use std::time::Duration;

use freya::prelude::*;

use crate::utils::matrix::CLIENT;
use crate::utils::on_tokio;
use crate::utils::users::{self, UserInfo};

/// Wait after the last keystroke before searching.
const DEBOUNCE: Duration = Duration::from_millis(400);
const LIMIT: u64 = 10;

#[derive(Clone, Copy, PartialEq)]
pub(crate) struct UserSearch {
    /// Directory matches for the current query.
    pub results: State<Vec<UserInfo>>,
    pub searching: State<bool>,
    /// DM contacts, shown before anything is typed.
    pub suggestions: State<Vec<UserInfo>>,
}

impl UserSearch {
    /// What to list for `query`: DM contacts when it's empty; otherwise the
    /// matching contacts first (they include bridged users, who are not in the
    /// directory), then directory results not already listed.
    pub fn shown(&self, query: &str) -> Vec<UserInfo> {
        let query = query.trim().to_lowercase();
        let contacts = self.suggestions.read();
        if query.is_empty() {
            return contacts.clone();
        }
        let mut shown: Vec<UserInfo> = contacts
            .iter()
            .filter(|u| {
                u.user_id.to_lowercase().contains(&query)
                    || u.display_name.to_lowercase().contains(&query)
            })
            .cloned()
            .collect();
        for user in self.results.read().iter() {
            if !shown.iter().any(|u| u.user_id == user.user_id) {
                shown.push(user.clone());
            }
        }
        shown
    }
}

/// Debounced user-directory search on `query`, plus DM suggestions. A newer
/// query discards the results of older ones.
pub(crate) fn use_user_search(query: State<String>) -> UserSearch {
    let search = UserSearch {
        results: use_state(Vec::new),
        searching: use_state(|| false),
        suggestions: use_state(Vec::new),
    };
    let mut generation = use_state(|| 0u64);

    use_hook(move || {
        let mut suggestions = search.suggestions;
        spawn(async move {
            if let Some(contacts) = on_tokio(users::dm_contacts()).await {
                suggestions.set(contacts);
            }
        });
    });

    let text = query.read().clone();
    use_side_effect_with_deps(&text, move |text: &String| {
        let UserSearch {
            mut results,
            mut searching,
            ..
        } = search;
        let current = *generation.peek() + 1;
        generation.set(current);
        results.set(vec![]);
        if text.trim().is_empty() {
            searching.set(false);
            return;
        }
        let text = text.clone();
        spawn(async move {
            timer(DEBOUNCE).await;
            if *generation.peek() != current {
                return;
            }
            searching.set(true);
            let Some(client) = CLIENT.get().cloned() else {
                searching.set(false);
                return;
            };
            let found = on_tokio(async move { users::search(&client, &text, LIMIT).await }).await;
            if *generation.peek() == current {
                results.set(found.unwrap_or_default());
                searching.set(false);
            }
        });
    });

    search
}
