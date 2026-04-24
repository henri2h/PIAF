use std::{cell::RefCell, rc::Rc, sync::Arc};

use freya::prelude::*;
use tokio::sync::mpsc::UnboundedSender;

use crate::utils::const_values::AppColors;

use super::{MessageContent, MessageItem, MsgAction, message_action_popup};

#[allow(clippy::too_many_arguments)]
pub(super) fn action_popup_overlay(
    area: Area,
    popup_msg: MessageItem,
    mut popup_state: State<Option<(Area, MessageItem)>>,
    action_tx: Arc<UnboundedSender<MsgAction>>,
    mut reply_info: State<Option<(String, String, String)>>,
    mut detail_modal: State<Option<MessageItem>>,
    c: AppColors,
) -> Element {
    use message_action_popup::PopupAction;

    let event_id = popup_msg.event_id.clone();
    let is_me = popup_msg.is_me;

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

    let reply_body = match &popup_msg.content {
        MessageContent::Text(t) => t.clone(),
        MessageContent::Image { .. } => "[Image]".to_string(),
        MessageContent::Notice(_) => "[Notice]".to_string(),
    };

    let mut actions: Vec<PopupAction> = vec![
        PopupAction {
            icon: freya_icons::lucide::reply(),
            label: "Reply",
            color: c.on_surface,
            on_press: Box::new({
                let eid = event_id.clone();
                let sender = popup_msg.sender_name.clone();
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
                let msg_clone = popup_msg.clone();
                move || {
                    *detail_modal.write() = Some(msg_clone.clone());
                    *popup_state.write() = None;
                }
            }),
        },
    ];

    if is_me {
        if let Some(eid) = event_id.clone() {
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
        area,
        c,
        move || *popup_state.write() = None,
        on_react,
        actions,
    )
}
