use std::sync::Mutex;

pub struct UserInfo {
    pub user_id: String,
    pub display_name: String,
    pub avatar_mxc: Option<String>,
}

pub struct GroupDraft {
    pub invitees: Vec<UserInfo>,
    pub name: String,
    pub encrypted: bool,
}

pub static GROUP_DRAFT: Mutex<GroupDraft> = Mutex::new(GroupDraft {
    invitees: Vec::new(),
    name: String::new(),
    encrypted: true,
});

/// Holds the display info for a pending DM (set before navigating to PendingDm).
pub static PENDING_DM: Mutex<Option<UserInfo>> = Mutex::new(None);
