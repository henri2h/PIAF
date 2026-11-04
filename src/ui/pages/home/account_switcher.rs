//! The avatar menu: accounts (switch, sign in again, sign out), add an
//! account, settings. A bottom sheet on Android, a popup elsewhere.

use freya::prelude::*;
use freya_icons::lucide;

use crate::Route;
use crate::ui::components::{IconButton, ListItem, PersonRow, confirm_dialog};
use crate::utils::accounts::{self, Account};
use crate::utils::avatars::AvatarSource;
use crate::utils::const_values::AppColors;
use crate::utils::use_app_colors;

#[derive(PartialEq)]
pub(super) struct AccountSwitcher {
    pub open: State<bool>,
    /// Our display name, already fetched by the app bar.
    pub my_name: String,
}

impl Component for AccountSwitcher {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut open = self.open;
        // Account to sign out of, waiting for confirmation.
        let mut signing_out: State<Option<Account>> = use_state(|| None);

        let pending = signing_out.read().clone();
        if let Some(account) = pending {
            let id = account.id.clone();
            return confirm_dialog(
                format!("Sign out of {}?", account.name()),
                "Its local data on this device will be deleted. Without a key backup or another signed-in device, encrypted messages can't be read again.",
                "Sign out",
                move || signing_out.set(None),
                move || {
                    signing_out.set(None);
                    open.set(false);
                    let id = id.clone();
                    // On tokio: a Freya task would be cancelled when this dialog unmounts.
                    tokio::spawn(async move {
                        crate::utils::matrix::logout_inactive(&id).await;
                    });
                },
            )
            .into_element();
        }
        if !*open.read() {
            return rect().into_element();
        }

        let registry = accounts::registry();
        let active_id = registry.active.clone();
        let mut close_then = move |route: Route| {
            open.set(false);
            crate::app::navigation::push(route);
        };

        let rows = registry.accounts.into_iter().map(|account| {
            let is_active = active_id.as_deref() == Some(account.id.as_str());
            let mut row = if is_active {
                let name = if self.my_name.is_empty() {
                    account.name().to_string()
                } else {
                    self.my_name.clone()
                };
                PersonRow::new(&account.user_id, name, Some(AvatarSource::Me)).trailing(
                    SvgViewer::new(lucide::check())
                        .color(c.primary)
                        .width(Size::px(20.))
                        .height(Size::px(20.)),
                )
            } else {
                PersonRow::new(
                    &account.user_id,
                    account.name(),
                    accounts::avatar(&account.id).map(AvatarSource::Bytes),
                )
                .trailing(sign_out_button(account.clone(), signing_out, c))
            };
            if account.expired {
                row = row.subtitle("Signed out · tap to sign in again");
            }
            if !is_active || account.expired {
                let id = account.id.clone();
                let expired = account.expired;
                row = row.on_press(move |_| {
                    if expired {
                        // Signing in again replaces the expired entry.
                        close_then(Route::LoginPage);
                    } else {
                        switch_to(&id);
                    }
                });
            }
            rect().key(&account.id).child(row).into_element()
        });

        let actions = [
            (lucide::user_plus(), "Add account", Route::LoginPage),
            (lucide::settings(), "Settings", Route::Settings),
        ]
        .into_iter()
        .map(|(icon, text, route)| {
            ListItem::new(text)
                .leading(
                    rect().width(Size::px(42.)).center().child(
                        SvgViewer::new(icon)
                            .color(c.on_surface_variant)
                            .width(Size::px(22.))
                            .height(Size::px(22.)),
                    ),
                )
                .on_press(move |_| close_then(route.clone()))
                .into_element()
        });

        let content = rect()
            .vertical()
            .width(Size::fill())
            .children(rows)
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::px(1.))
                    .margin(Gaps::new_symmetric(4., 16.))
                    .background(c.outline_variant),
            )
            .children(actions);

        #[cfg(target_os = "android")]
        let menu = crate::ui::components::bottom_sheet(c, move || open.set(false))
            .title("Accounts")
            .child(content)
            .into_element();
        #[cfg(not(target_os = "android"))]
        let menu = Popup::new()
            .on_close_request(move |_| open.set(false))
            .child(PopupTitle::new("Accounts".to_string()))
            .child(content)
            .into_element();
        menu
    }
}

fn sign_out_button(
    account: Account,
    mut signing_out: State<Option<Account>>,
    c: AppColors,
) -> Element {
    IconButton::new(lucide::log_out(), c.on_surface_variant, move |_| {
        signing_out.set(Some(account.clone()))
    })
    .tooltip("Sign out")
    .size(40., 18.)
    .into_element()
}

fn switch_to(id: &str) {
    crate::utils::haptics::play(crate::utils::haptics::Haptic::Click);
    accounts::switch_to(id, None);
}
