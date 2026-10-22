use std::cell::RefCell;
use std::rc::Rc;
use std::time::Duration;

use freya::prelude::*;
use freya::text_edit::*;
use freya_components::cursor_blink::use_cursor_blink;

use crate::ui::components::IconButton;
use crate::utils::const_values::AppColors;
use crate::utils::haptics::{self, Haptic};
use crate::utils::ime::{self, ImeEvent, ImeKind};
use crate::utils::ime_edit::{Composing, apply_ime_event, finish_composition};
use crate::utils::insets::status_bar_inset;
use crate::utils::use_app_colors;

/// The search page's query field: no box, it's the app bar's own text. On
/// Android the keyboard types through the IME bridge (suggestions, accents,
/// a search key), like the composer. A clear button ends it while not empty.
#[derive(PartialEq)]
pub struct SearchField {
    pub value: State<String>,
    pub placeholder: &'static str,
    /// The keyboard's search key (or Enter): the query is final.
    pub on_submit: EventHandler<String>,
    /// Hides the keyboard when set (results scrolled); reset by the field.
    pub dismiss: State<bool>,
    /// Focused on mount (keyboard up).
    pub auto_focus: bool,
    pub font_size: f32,
}

impl Component for SearchField {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut value = self.value;
        let mut dismiss = self.dismiss;
        let on_submit = self.on_submit.clone();
        let a11y_id = use_a11y();
        let focus = use_focus(a11y_id);
        let holder = use_state(ParagraphHolder::default);
        let composing: Composing = use_hook(|| Rc::new(RefCell::new(None)));
        let ime_owner = use_hook(|| Rc::new(std::cell::Cell::new(0u64)));
        let mut editable = use_editable(String::new, EditableConfig::new);
        // Touch editing: long press, edit menu (cut / copy / paste / select all).
        let touch = use_touch_edit();
        let editor_state = *editable.editor();

        // Starts on the kept query, cursor at the end.
        let auto_focus = self.auto_focus;
        use_hook(move || {
            set_text(editor_state, value.peek().clone());
            if auto_focus {
                a11y_id.request_focus();
            }
        });

        let is_focused = focus().is_focused();
        let text_now = move || editable.editor().peek().rope().to_string();
        let cursor_now = move || editable.editor().peek().cursor_pos();

        // Edits → the query. The query changed elsewhere (clear, a recent
        // search) → the editor and the keyboard.
        use_side_effect(move || {
            let text = editable.editor().read().rope().to_string();
            if *value.peek() != text {
                value.set(text);
            }
        });
        {
            let composing = composing.clone();
            use_side_effect(move || {
                let query = value.read().clone();
                if query != editable.editor().peek().rope().to_string() {
                    finish_composition(&composing);
                    set_text(editor_state, query.clone());
                    if focus.peek().is_focused() {
                        ime::sync(&query, query.encode_utf16().count());
                    }
                }
            });
        }
        {
            let ime_owner = ime_owner.clone();
            let composing = composing.clone();
            use_side_effect_with_deps(&is_focused, move |&focused| {
                if focused {
                    finish_composition(&composing);
                    ime_owner.set(ime::show(&text_now(), cursor_now(), ImeKind::Search));
                } else {
                    ime::hide(ime_owner.get());
                }
            });
        }
        {
            let ime_owner = ime_owner.clone();
            use_side_effect(move || {
                if *dismiss.read() {
                    dismiss.set(false);
                    a11y_id.request_unfocus();
                    ime::hide(ime_owner.get());
                }
            });
        }
        {
            let ime_owner = ime_owner.clone();
            use_drop(move || ime::hide(ime_owner.get()));
        }
        {
            let composing = composing.clone();
            let on_submit = on_submit.clone();
            let ime_owner = ime_owner.clone();
            use_hook(move || {
                crate::utils::bridge_watch(&ime::events(), move |_| {
                    if !focus.peek().is_focused() {
                        return;
                    }
                    for event in ime::drain() {
                        if matches!(event, ImeEvent::Action) {
                            a11y_id.request_unfocus();
                            ime::hide(ime_owner.get());
                            on_submit.call(text_now());
                        } else {
                            apply_ime_event(&mut editable.editor_mut().write(), &composing, event);
                        }
                    }
                });
            });
        }

        let (text, cursor_index, selection) = {
            let editor = editable.editor().read();
            let cursor = is_focused.then(|| editor.cursor_pos());
            let selection = editor.get_visible_selection(EditorLine::SingleParagraph);
            (editor.rope().to_string(), cursor, selection)
        };
        let (mut blink, cursor_color) = use_cursor_blink(is_focused, Color::from(c.primary));
        use_side_effect_with_deps(&(text.clone(), cursor_index), move |_| blink.reset());

        let on_key_down = {
            let on_submit = on_submit.clone();
            let composing = composing.clone();
            move |e: Event<KeyboardEventData>| {
                finish_composition(&composing);
                touch.show_menu(false);
                match e.key {
                    Key::Named(NamedKey::Enter) => on_submit.call(text_now()),
                    Key::Named(NamedKey::Escape) => a11y_id.request_unfocus(),
                    _ => editable.process_event(EditableEvent::KeyDown {
                        key: &e.key,
                        modifiers: e.modifiers,
                        editor_line: None,
                        holder: None,
                    }),
                }
            }
        };
        let on_pointer_down = move |e: Event<PointerEventData>| {
            a11y_id.request_focus();
            editable.process_event(EditableEvent::Down {
                location: e.element_location(),
                editor_line: EditorLine::SingleParagraph,
                holder: &holder.read(),
            });
        };

        let is_empty = text.is_empty();
        let field = rect()
            .width(Size::flex(1.))
            .height(Size::fill())
            .main_align(Alignment::Center)
            .a11y_id(a11y_id)
            .a11y_focusable(true)
            .a11y_role(AccessibilityRole::SearchInput)
            .on_key_down(on_key_down)
            .on_key_up(move |e: Event<KeyboardEventData>| {
                editable.process_event(EditableEvent::KeyUp { key: &e.key });
            })
            .on_global_pointer_up(move |e: Event<PointerEventData>| {
                editable.process_event(EditableEvent::Release);
                if matches!(*e, PointerEventData::Touch(_)) {
                    touch.touch_end(editable.editor().peek().has_any_selection());
                }
            })
            .child(
                // The line's own box: the placeholder overlays it, cursor still
                // at the start of the empty text.
                rect()
                    .width(Size::fill())
                    .child(
                        paragraph()
                            .holder(holder.read().clone())
                            .on_pointer_down(on_pointer_down)
                            .on_touch_start(move |e: Event<TouchEventData>| {
                                touch.touch_start(e.global_location, editable, || {
                                    haptics::play(Haptic::HeavyClick)
                                })
                            })
                            .on_touch_move(move |e: Event<TouchEventData>| {
                                touch.touch_move(e.global_location);
                                touch.drag(
                                    editable,
                                    &holder.read(),
                                    EditorLine::SingleParagraph,
                                    e.element_location,
                                );
                            })
                            .on_touch_end(move |_: Event<TouchEventData>| {
                                touch.touch_end(editable.editor().peek().has_any_selection())
                            })
                            .highlights(selection.map(|h| vec![h]))
                            .cursor_index(cursor_index)
                            .cursor_color(cursor_color)
                            .width(Size::fill())
                            .max_lines(1)
                            .font_size(self.font_size)
                            .color(c.on_surface)
                            .span(text),
                    )
                    .maybe_child(is_empty.then(|| {
                        label()
                            .position(Position::new_absolute().top(0.).left(0.))
                            .text(self.placeholder)
                            .max_lines(1)
                            .font_size(self.font_size)
                            .color(c.on_surface_faint)
                    })),
            );

        // Below the field: above it is the status bar.
        let edit_menu = (is_focused && touch.is_menu_shown()).then(|| {
            let has_selection = editable.editor().read().has_any_selection();
            let composing = composing.clone();
            let on_action = move |action: EditAction| {
                finish_composition(&composing);
                action.apply(editable);
                // The keyboard edits its own copy of the text: re-sync it.
                ime::sync(&text_now(), cursor_now());
                // Select all keeps the menu up, to copy or cut next.
                touch.show_menu(action == EditAction::SelectAll);
            };
            rect()
                .position(Position::new_absolute().top(56.).left(0.))
                .layer(Layer::Overlay)
                .child(EditMenu::new(
                    EditAction::available(has_selection, true),
                    on_action,
                ))
        });

        rect()
            .horizontal()
            .width(Size::flex(1.))
            .height(Size::fill())
            .content(Content::Flex)
            .cross_align(Alignment::Center)
            .maybe_child(edit_menu)
            .child(field)
            .maybe_child((!is_empty).then(|| {
                IconButton::new(freya_icons::lucide::x(), c.on_surface_variant, move |_| {
                    value.set(String::new());
                    a11y_id.request_focus();
                })
                .tooltip("Clear")
                .size(40., 20.)
            }))
    }
}

/// A search page's bar (under the status bar): back, `field`, a divider.
pub fn search_app_bar(field: SearchField, c: AppColors) -> Rect {
    rect()
        .vertical()
        .width(Size::fill())
        .child(
            rect()
                .width(Size::fill())
                .height(Size::px(status_bar_inset())),
        )
        .child(
            rect()
                .horizontal()
                .width(Size::fill())
                .height(Size::px(64.))
                .content(Content::Flex)
                .cross_align(Alignment::Center)
                .padding(Gaps::new(0., 8., 0., 4.))
                .spacing(4.)
                .child(
                    IconButton::new(
                        freya_icons::lucide::arrow_left(),
                        c.on_surface_variant,
                        |_| crate::app::navigation::go_back_or_home(),
                    )
                    .size(48., 22.),
                )
                .child(field),
        )
        .child(
            rect()
                .width(Size::fill())
                .height(Size::px(1.))
                .background(c.outline_variant_light),
        )
}

fn set_text(mut editor: State<RopeEditor>, text: String) {
    let end = text.encode_utf16().count();
    *editor.write() = RopeEditor::new(
        text,
        TextSelection::new_cursor(end),
        0,
        EditorHistory::new(Duration::from_millis(10)),
    );
}

#[cfg(test)]
mod tests {
    use std::cell::RefCell;

    use freya::prelude::*;
    use freya_testing::prelude::launch_test;

    use super::SearchField;

    thread_local! {
        static QUERY: RefCell<String> = RefCell::new(String::new());
        static SUBMITTED: RefCell<Option<String>> = RefCell::new(None);
    }

    fn app() -> impl IntoElement {
        use_init_theme(light_theme);
        let value = use_state(String::new);
        let dismiss = use_state(|| false);
        QUERY.with(|q| *q.borrow_mut() = value.read().clone());
        rect()
            .width(Size::px(400.))
            .height(Size::px(64.))
            .child(SearchField {
                value,
                placeholder: "Search",
                on_submit: EventHandler::new(|q: String| {
                    SUBMITTED.with(|s| *s.borrow_mut() = Some(q))
                }),
                dismiss,
                auto_focus: true,
                font_size: 18.,
            })
    }

    #[test]
    fn types_submits_and_clears() {
        // The keyboard bridge listens on tokio.
        let runtime = tokio::runtime::Runtime::new().unwrap();
        let _guard = runtime.enter();
        let mut test = launch_test(app);
        test.sync_and_update();
        // Focused on mount: typing goes straight in.
        test.write_text("abc");
        test.sync_and_update();
        assert_eq!(QUERY.with(|q| q.borrow().clone()), "abc");

        test.press_key(Key::Named(NamedKey::Enter));
        test.sync_and_update();
        assert_eq!(
            SUBMITTED.with(|s| s.borrow().clone()),
            Some("abc".to_string())
        );

        // The clear button sits at the right end of the field.
        test.click_cursor((380., 32.));
        test.sync_and_update();
        assert_eq!(QUERY.with(|q| q.borrow().clone()), "");
    }

    #[test]
    fn long_press_then_cut() {
        let runtime = tokio::runtime::Runtime::new().unwrap();
        let _guard = runtime.enter();
        let mut test = launch_test(app);
        test.sync_and_update();
        test.write_text("abc");
        test.sync_and_update();

        test.press_touch((15., 32.));
        test.poll(
            std::time::Duration::from_millis(20),
            std::time::Duration::from_millis(600),
        );
        // A resting finger still moves a little: the word stays selected.
        test.move_touch((17., 32.));
        test.release_touch((17., 32.));
        test.sync_and_update();

        let cut = test
            .find(|node, element| {
                Label::try_downcast(element)
                    .filter(|l| l.text.as_ref() == "Cut")
                    .map(|_| node.layout().area.center().to_f64())
            })
            .expect("edit menu after a long press");
        test.click_cursor(cut);
        test.sync_and_update();
        assert_eq!(QUERY.with(|q| q.borrow().clone()), "");
    }
}
