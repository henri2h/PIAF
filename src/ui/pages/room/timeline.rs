use std::sync::Arc;

use eyeball_im::VectorDiff;
use matrix_sdk_ui::timeline::TimelineItem;

use crate::utils::{format_date_key, format_date_label};

pub(super) fn apply_diff(items: &mut Vec<Arc<TimelineItem>>, diff: VectorDiff<Arc<TimelineItem>>) {
    match diff {
        VectorDiff::Append { values } => items.extend(values),
        VectorDiff::Clear => items.clear(),
        VectorDiff::PushFront { value } => items.insert(0, value),
        VectorDiff::PushBack { value } => items.push(value),
        VectorDiff::PopFront => {
            if !items.is_empty() {
                items.remove(0);
            }
        }
        VectorDiff::PopBack => {
            items.pop();
        }
        VectorDiff::Insert { index, value } => items.insert(index, value),
        VectorDiff::Set { index, value } => {
            if index < items.len() {
                items[index] = value;
            }
        }
        VectorDiff::Remove { index } => {
            if index < items.len() {
                items.remove(index);
            }
        }
        VectorDiff::Truncate { length } => items.truncate(length),
        VectorDiff::Reset { values } => {
            items.clear();
            items.extend(values);
        }
    }
}

pub(super) fn date_label_for(items: &[Arc<TimelineItem>], idx: usize) -> Option<String> {
    let curr = items[idx].as_event().map(|e| format_date_key(e.timestamp()))?;
    let prev = idx
        .checked_sub(1)
        .and_then(|i| items[i].as_event().map(|e| format_date_key(e.timestamp())));
    if prev.as_deref() != Some(curr.as_str()) {
        Some(format_date_label(&curr))
    } else {
        None
    }
}
