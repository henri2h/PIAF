use freya::prelude::*;

use super::{Avatar, ListItem};
use crate::utils::avatars::AvatarSource;
use crate::utils::const_values::AppColors;
use crate::utils::id_color;

/// [`ListItem`] for a person: avatar, name (with an optional `badge`), a
/// second line (the user ID unless set) and an optional `trailing` element.
/// Pressable when `on_press` is set.
pub struct PersonRow {
    pub user_id: String,
    pub name: String,
    pub avatar: Option<AvatarSource>,
    pub subtitle: Option<String>,
    pub badge: Option<Element>,
    pub trailing: Option<Element>,
    pub on_press: Option<EventHandler<()>>,
}

impl PersonRow {
    pub fn new(
        user_id: impl Into<String>,
        name: impl Into<String>,
        avatar: Option<AvatarSource>,
    ) -> Self {
        Self {
            user_id: user_id.into(),
            name: name.into(),
            avatar,
            subtitle: None,
            badge: None,
            trailing: None,
            on_press: None,
        }
    }

    pub fn subtitle(mut self, subtitle: impl Into<String>) -> Self {
        self.subtitle = Some(subtitle.into());
        self
    }

    pub fn badge(mut self, badge: impl IntoElement) -> Self {
        self.badge = Some(badge.into_element());
        self
    }

    pub fn trailing(mut self, trailing: impl IntoElement) -> Self {
        self.trailing = Some(trailing.into_element());
        self
    }

    pub fn on_press(mut self, on_press: impl FnMut(()) + 'static) -> Self {
        self.on_press = Some(EventHandler::new(on_press));
        self
    }
}

/// The handler is left out: rows only re-render on what they show.
impl PartialEq for PersonRow {
    fn eq(&self, other: &Self) -> bool {
        self.user_id == other.user_id
            && self.name == other.name
            && self.avatar == other.avatar
            && self.subtitle == other.subtitle
            && self.badge == other.badge
            && self.trailing == other.trailing
            && self.on_press.is_some() == other.on_press.is_some()
    }
}

/// Small filled label next to a name, e.g. "Admin".
pub fn badge(text: &'static str, c: AppColors) -> Rect {
    rect()
        .padding(Gaps::new(2., 6., 2., 6.))
        .corner_radius(8.)
        .background(c.primary)
        .child(label().text(text).font_size(10.).color(c.on_primary))
}

impl Component for PersonRow {
    fn render(&self) -> impl IntoElement {
        let mut item = ListItem::new(self.name.clone())
            .supporting(
                self.subtitle
                    .clone()
                    .unwrap_or_else(|| self.user_id.clone()),
            )
            .leading(Avatar {
                size: 42.,
                source: self.avatar.clone(),
                name: self.name.clone(),
                color: id_color(&self.user_id),
            });
        if let Some(badge) = self.badge.clone() {
            item = item.badge(badge);
        }
        if let Some(trailing) = self.trailing.clone() {
            item = item.trailing(trailing);
        }
        if let Some(on_press) = self.on_press.clone() {
            item = item.on_press(move |_| on_press.call(()));
        }
        item
    }
}
