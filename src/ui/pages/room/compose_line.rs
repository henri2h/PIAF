use freya::prelude::*;
use freya::text_edit::*;
use freya_components::cursor_blink::use_cursor_blink;

use crate::utils::const_values::AppColors;

/// One line of the composer: text, selection and blinking cursor.
#[derive(PartialEq)]
pub(super) struct ComposeLine {
    pub line_index: usize,
    pub editable: UseEditable,
    pub c: AppColors,
    pub is_focused: bool,
    pub touch: TouchEdit,
    /// Measured height of each line (wrapped lines are taller), for the composer's height.
    pub heights: State<Vec<f32>>,
}

impl Component for ComposeLine {
    fn render_key(&self) -> DiffKey {
        (&self.line_index).into()
    }

    fn render(&self) -> impl IntoElement {
        let line_index = self.line_index;
        let mut editable = self.editable;
        let c = self.c;
        let touch = self.touch;
        let mut heights = self.heights;
        let holder = use_state(ParagraphHolder::default);

        let (text, is_active, cursor_index, highlights) = {
            let editor = editable.editor().read();
            let text = editor
                .line(line_index)
                .map(|l| l.text.to_string())
                .unwrap_or_default();
            let is_active = editor.cursor_row() == line_index;
            // Only draw the cursor when this line is active AND the bar has focus.
            // This prevents the cursor from appearing under the placeholder text.
            let cursor_index = if is_active && self.is_focused {
                Some(editor.cursor_col())
            } else {
                None
            };
            let highlights = editor.get_visible_selection(EditorLine::Paragraph(line_index));
            (text, is_active, cursor_index, highlights)
        };

        // Blink when this line is active and the composer has keyboard focus.
        let (mut blink_timeout, cursor_color) = use_cursor_blink(
            is_active && self.is_focused,
            Color::from(c.compose_edit_text),
        );
        // Typing or moving the cursor keeps it solid; it only blinks once idle.
        use_side_effect_with_deps(&(text.clone(), cursor_index), move |_| {
            blink_timeout.reset();
        });

        let on_sized = move |e: Event<SizedEventData>| {
            let height = e.area.height();
            let known = heights.peek().get(line_index).copied();
            if known != Some(height) {
                let mut heights = heights.write();
                if heights.len() <= line_index {
                    heights.resize(line_index + 1, 0.);
                }
                heights[line_index] = height;
            }
        };

        // Pointer, not mouse: a tap places the cursor on touch screens too.
        let on_pointer_down = move |e: Event<PointerEventData>| {
            editable.process_event(EditableEvent::Down {
                location: e.element_location(),
                editor_line: EditorLine::Paragraph(line_index),
                holder: &holder.read(),
            });
        };

        let on_mouse_move = move |e: Event<MouseEventData>| {
            editable.process_event(EditableEvent::Move {
                location: e.element_location,
                editor_line: EditorLine::Paragraph(line_index),
                holder: &holder.read(),
            });
        };

        // After a long press, the selection follows the finger.
        let on_touch_move = move |e: Event<TouchEventData>| {
            touch.drag(
                editable,
                &holder.read(),
                EditorLine::Paragraph(line_index),
                e.element_location,
            );
        };

        paragraph()
            .holder(holder.read().clone())
            .on_touch_move(on_touch_move)
            .on_sized(on_sized)
            .on_pointer_down(on_pointer_down)
            .on_mouse_move(on_mouse_move)
            .cursor_index(cursor_index)
            .cursor_color(cursor_color)
            .highlights(highlights.map(|h| vec![h]))
            .width(Size::fill())
            .font_size(16.)
            .color(c.compose_edit_text)
            .span(text)
    }
}
