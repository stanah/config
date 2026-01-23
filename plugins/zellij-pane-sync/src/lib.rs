use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use zellij_tile::prelude::*;

/// Pane Sync Plugin for Zellij
///
/// Synchronizes upper stacked panes with lower pane focus.
/// When you focus a lower pane (e.g., Claude Code), the corresponding
/// upper pane (e.g., lazygit, shell, yazi) becomes visible in the stack.

#[derive(Default, Serialize, Deserialize)]
struct State {
    /// Map of lower pane column index -> upper stacked pane IDs for that column
    column_upper_panes: BTreeMap<usize, Vec<u32>>,
    /// Map of lower pane ID -> column index
    lower_pane_columns: BTreeMap<u32, usize>,
    /// Current pane manifest
    panes: PaneManifest,
    /// Currently focused lower pane ID
    focused_lower_pane: Option<u32>,
    /// Last synced column to avoid redundant updates
    last_synced_column: Option<usize>,
    /// Permissions granted
    permissions_granted: bool,
    /// Plugin configuration: number of columns
    columns: usize,
    /// Debug mode
    debug: bool,
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, configuration: BTreeMap<String, String>) {
        // Parse configuration
        self.columns = configuration
            .get("columns")
            .and_then(|s| s.parse().ok())
            .unwrap_or(4);

        self.debug = configuration
            .get("debug")
            .map(|s| s == "true")
            .unwrap_or(false);

        // Request necessary permissions
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
        ]);

        // Subscribe to pane focus events
        subscribe(&[
            EventType::PaneUpdate,
            EventType::PermissionRequestResult,
        ]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PermissionRequestResult(status) => {
                self.permissions_granted = status == PermissionStatus::Granted;
            }
            Event::PaneUpdate(manifest) => {
                if self.permissions_granted {
                    self.panes = manifest;
                    self.analyze_layout();
                    self.sync_upper_pane();
                }
            }
            _ => {}
        }
        self.debug // Only render if debug mode
    }

    fn render(&mut self, _rows: usize, _cols: usize) {
        if self.debug {
            println!("=== Pane Sync Debug ===");
            println!("Lower panes: {:?}", self.lower_pane_columns);
            println!("Upper columns: {:?}", self.column_upper_panes);
            println!("Focused: {:?}", self.focused_lower_pane);
        }
    }
}

impl State {
    /// Analyze the current pane layout to identify upper stacked panes and lower panes
    fn analyze_layout(&mut self) {
        self.column_upper_panes.clear();
        self.lower_pane_columns.clear();

        // Collect all terminal panes (excluding plugins)
        let terminal_panes: Vec<_> = self
            .panes
            .panes
            .values()
            .flat_map(|panes| panes.iter())
            .filter(|p| !p.is_plugin)
            .collect();

        if terminal_panes.len() < 2 {
            return;
        }

        // Find Y coordinate boundaries
        let y_coords: Vec<usize> = terminal_panes.iter().map(|p| p.pane_y).collect();
        let min_y = *y_coords.iter().min().unwrap_or(&0);
        let max_y = *y_coords.iter().max().unwrap_or(&0);

        // If all panes at same Y, no upper/lower distinction
        if min_y == max_y {
            return;
        }

        // Calculate threshold to separate upper and lower rows
        let y_threshold = min_y + (max_y - min_y) / 2;

        // Separate panes into upper and lower
        let mut upper_panes: Vec<_> = terminal_panes
            .iter()
            .filter(|p| p.pane_y <= y_threshold)
            .cloned()
            .collect();
        let mut lower_panes: Vec<_> = terminal_panes
            .iter()
            .filter(|p| p.pane_y > y_threshold)
            .cloned()
            .collect();

        // Sort by X position to determine columns
        upper_panes.sort_by_key(|p| p.pane_x);
        lower_panes.sort_by_key(|p| p.pane_x);

        // Map lower panes to column indices
        for (idx, pane) in lower_panes.iter().enumerate() {
            self.lower_pane_columns.insert(pane.id, idx);
        }

        // Group upper panes by their approximate X position (for stacked panes)
        // Stacked panes share the same X position
        let mut x_groups: BTreeMap<usize, Vec<u32>> = BTreeMap::new();
        for pane in &upper_panes {
            x_groups
                .entry(pane.pane_x)
                .or_default()
                .push(pane.id);
        }

        // Map X groups to column indices
        for (col_idx, (_, pane_ids)) in x_groups.into_iter().enumerate() {
            self.column_upper_panes.insert(col_idx, pane_ids);
        }
    }

    /// Sync the upper pane stack based on which lower pane is focused
    fn sync_upper_pane(&mut self) {
        // Find currently focused pane
        let focused = self
            .panes
            .panes
            .values()
            .flat_map(|panes| panes.iter())
            .find(|p| p.is_focused && !p.is_plugin);

        let Some(focused_pane) = focused else {
            return;
        };

        // Check if this is a lower pane
        let Some(&column) = self.lower_pane_columns.get(&focused_pane.id) else {
            return; // Not a lower pane, ignore
        };

        // Check if we already synced this column
        if self.last_synced_column == Some(column)
            && self.focused_lower_pane == Some(focused_pane.id) {
            return;
        }

        self.focused_lower_pane = Some(focused_pane.id);
        self.last_synced_column = Some(column);

        // Find the corresponding upper pane(s) for this column
        if let Some(upper_pane_ids) = self.column_upper_panes.get(&column) {
            if let Some(&upper_pane_id) = upper_pane_ids.first() {
                // Bring the upper pane to front (in stack) without stealing focus
                // We briefly focus it then return to the lower pane
                let lower_pane_id = focused_pane.id;

                // Focus upper pane to bring it to front of stack
                focus_terminal_pane(upper_pane_id, false);

                // Immediately return focus to the lower pane
                focus_terminal_pane(lower_pane_id, false);
            }
        }
    }
}
