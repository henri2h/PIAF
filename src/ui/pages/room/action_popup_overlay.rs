use std::{cell::RefCell, rc::Rc, sync::Arc};

use freya::prelude::*;
use matrix_sdk::ruma::events::room::message::MessageType;
use matrix_sdk_ui::timeline::{TimelineDetails, TimelineItem, TimelineItemContent};
use tokio::sync::mpsc::UnboundedSender;

use crate::utils::const_values::AppColors;

use super::{MsgAction, message_action_popup};

#[allow(clippy::too_many_arguments)]
pub(super) fn action_popup_overlay(
    mut popup_state: State<Option<Arc<TimelineItem>>>,
    my_user_id: Option<String>,
    action_tx: Arc<UnboundedSender<MsgAction>>,
    mut reply_info: State<Option<(String, String, String)>>,
    mut edit_info: State<Option<(String, String)>>,
    mut detail_modal: State<Option<Arc<TimelineItem>>>,
    c: AppColors,
) -> Element {
    use message_action_popup::PopupAction;

    let popup_item = popup_state.read().clone();

    let Some(popup_item) = popup_item else {
        return Popup::new().show(false).into();
    };

    let Some(event) = popup_item.as_event() else {
        return Popup::new().show(false).into();
    };

    let event_id = event.event_id().map(|id| id.to_string());
    let is_me = my_user_id.as_deref() == Some(event.sender().as_str());

    let (reply_body, edit_body): (String, Option<String>) =
        if let TimelineItemContent::MsgLike(m) = event.content() {
            if let Some(msg) = m.as_message() {
                match msg.msgtype() {
                    MessageType::Text(t) => (t.body.clone(), Some(t.body.clone())),
                    _ => ("[Message]".to_string(), None),
                }
            } else {
                return Popup::new().show(false).into();
            }
        } else {
            return Popup::new().show(false).into();
        };

    let sender_name: String = match event.sender_profile() {
        TimelineDetails::Ready(p) => p
            .display_name
            .clone()
            .unwrap_or_else(|| event.sender().to_string()),
        _ => event.sender().to_string(),
    };

    let on_react: Rc<RefCell<dyn FnMut(String)>> = {
        let eid = event_id.clone();
        let tx = action_tx.clone();
        Rc::new(RefCell::new(move |key: String| {
            if let Some(event_id) = &eid {
                let _ = tx.send(MsgAction::React {
                    event_id: event_id.clone(),
                    key,
                });
            }
            *popup_state.write() = None;
        }))
    };

    let mut actions: Vec<PopupAction> = vec![
        PopupAction {
            icon: freya_icons::lucide::reply(),
            label: "Reply",
            color: c.on_surface,
            on_press: Box::new({
                let eid = event_id.clone();
                let sender = sender_name;
                let body = reply_body;
                move || {
                    if let Some(event_id) = &eid {
                        *reply_info.write() =
                            Some((event_id.clone(), sender.clone(), body.clone()));
                    }
                    *popup_state.write() = None;
                }
            }),
        },
        PopupAction {
            icon: freya_icons::lucide::info(),
            label: "Details",
            color: c.on_surface,
            on_press: Box::new({
                let item_clone = popup_item.clone();
                move || {
                    *detail_modal.write() = Some(item_clone.clone());
                    *popup_state.write() = None;
                }
            }),
        },
    ];

    if is_me {
        if let (Some(eid), Some(body)) = (event_id.clone(), edit_body) {
            actions.push(PopupAction {
                icon: freya_icons::lucide::pencil(),
                label: "Edit",
                color: c.on_surface,
                on_press: Box::new(move || {
                    *edit_info.write() = Some((eid.clone(), body.clone()));
                    *popup_state.write() = None;
                }),
            });
        }
        if let Some(eid) = event_id {
            let tx = action_tx.clone();
            actions.push(PopupAction {
                icon: freya_icons::lucide::trash_2(),
                label: "Delete",
                color: c.error,
                on_press: Box::new(move || {
                    let _ = tx.send(MsgAction::Delete {
                        event_id: eid.clone(),
                    });
                    *popup_state.write() = None;
                }),
            });
        }
    }

    message_action_popup::action_popup(
        c,
        move || *popup_state.write() = None,
        on_react,
        actions,
    )
}
