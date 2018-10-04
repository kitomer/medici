-- 1 up
CREATE TABLE media_collection ( -- splits all media into distinct items
  collection_id INT PRIMARY KEY,
  collection_uid INT NOT NULL,
  collection_name TEXT NOT NULL DEFAULT '',
  -- access control columns
  acl_owner INT NOT NULL DEFAULT 1,             -- int not null default 1,
  acl_group INT NOT NULL DEFAULT 1,             -- int not null default 1,
  acl_unixperms INT NOT NULL DEFAULT 500,       -- int not null default 500,
  acl_status INT NOT NULL DEFAULT 2             -- int not null default 2,
);
CREATE TABLE media_item ( -- a single binary media item (image, video, document)
  item_id INT PRIMARY KEY, -- this _is_ the revision (the higher the newer)
  item_uid INT NOT NULL,
  item_hash TEXT NOT NULL DEFAULT '', -- used to identify revisions of the _same_ item (e.e.g useful for documents)
  item_collection_id INT NOT NULL DEFAULT 0, -- items can be grouped into distinct collections (string name each item belongs to ONE collection)
  item_source_url TEXT NOT NULL DEFAULT '', -- url of the original source (if any), can also be a file:///... url
  item_source_title TEXT NOT NULL DEFAULT '',
  item_source_details TEXT NOT NULL DEFAULT '',
  item_source_content TEXT NOT NULL DEFAULT '', -- document content in case the item is a document
  item_source_type TEXT NOT NULL DEFAULT '', -- e.g. “plaintext”, “markdown”, ...
  item_source_filename TEXT NOT NULL DEFAULT '', -- whole local filename of downloaded url (if processed this may be removed)
  item_source_last_downloaded DATETIME NOT NULL DEFAULT '00-00-0000 00:00:00',
  item_content_hash TEXT NOT NULL DEFAULT '', -- md5 of content
  item_title TEXT NOT NULL DEFAULT '',
  item_notes TEXT NOT NULL DEFAULT '',
  item_image_format TEXT NOT NULL DEFAULT '', -- used to derive local image and tumbnail url, e.g. jpeg|png|...
  item_stream_format TEXT NOT NULL DEFAULT '', -- used to derive local stream url, e.g. dash|...
  item_remote_url_image TEXT NOT NULL DEFAULT '',
  item_remote_url_thumbnail TEXT NOT NULL DEFAULT '',
  item_remote_url_stream TEXT NOT NULL DEFAULT '',
  item_created DATETIME NOT NULL,
  item_played DATETIME NOT NULL,
  item_num_played INT NOT NULL DEFAULT 0,
  item_votes TEXT NOT NULL DEFAULT '', -- sequence of votes (any user), e.g. “0,1,2,3...”
  item_final_vote INT NULL DEFAULT 0, -- e.g. 0..3 (worst..best)
    -- the votes are SORTED and the median is chosen
  -- when certain amount of votes is reached, the median is set as the item_votes field
  -- access control columns
  acl_owner INT NOT NULL DEFAULT 1,             -- int not null default 1,
  acl_group INT NOT NULL DEFAULT 1,             -- int not null default 1,
  acl_unixperms INT NOT NULL DEFAULT 500,       -- int not null default 500,
  acl_status INT NOT NULL DEFAULT 2             -- int not null default 2,
);
CREATE TABLE media_pile ( -- an identifier used to group various items (within same collection)
  pile_id INT PRIMARY KEY,
  pile_uid INT NOT NULL,
  pile_collection TEXT NOT NULL DEFAULT '', -- s.a., contained items that belong to a different collection are NOT allowed
  pile_parent_pile_id INT NOT NULL DEFAULT 0, -- optional
  pile_title TEXT NOT NULL DEFAULT '', -- hd|fullhd|music|4k|...
  -- access control columns
  acl_owner INT NOT NULL DEFAULT 1,             -- int not null default 1,
  acl_group INT NOT NULL DEFAULT 1,             -- int not null default 1,
  acl_unixperms INT NOT NULL DEFAULT 500,       -- int not null default 500,
  acl_status INT NOT NULL DEFAULT 2             -- int not null default 2,
);
CREATE TABLE media_pi ( -- piled-item
  pi_pile_id INT NOT NULL,
  pi_item_id INT NOT NULL,
  pi_index INT NOT NULL DEFAULT 0, -- used for ordering items inside a pile (need not be continuous)
  pi_relation TEXT  NOT NULL DEFAULT '' -- parent|child|preview|...
);
-- 1 down
DROP TABLE media_collection;
DROP TABLE media_item;
DROP TABLE media_pile;
DROP TABLE media_pi;

-- 2 up
-- profiles and groups of profiles
CREATE TABLE social_community (
  community_id INT PRIMARY KEY,
  community_uid INT NOT NULL,
  community_name TEXT NOT NULL DEFAULT '',
  -- access control columns
  acl_owner INT NOT NULL DEFAULT 1,             -- int not null default 1,
  acl_group INT NOT NULL DEFAULT 1,             -- int not null default 1,
  acl_unixperms INT NOT NULL DEFAULT 500,       -- int not null default 500,
  acl_status INT NOT NULL DEFAULT 2             -- int not null default 2,
);
CREATE TABLE social_profile ( -- login and profile information of a single mortal being
  profile_id INT PRIMARY KEY,
  profile_uid INT NOT NULL,
  profile_community_id INT NOT NULL DEFAULT 0,
  profile_username TEXT NOT NULL DEFAULT '', -- max 64 unicode characters
  profile_password TEXT NOT NULL DEFAULT '', -- sha256 with salt
  profile_email TEXT NOT NULL DEFAULT '', -- optional, only used for recovery
  profile_is_virtual BOOL NOT NULL DEFAULT 0, -- if 1 then the profile was added by someone else
  -- access control columns
  acl_owner INT NOT NULL DEFAULT 1,             -- int not null default 1,
  acl_group INT NOT NULL DEFAULT 1,             -- int not null default 1,
  acl_unixperms INT NOT NULL DEFAULT 500,       -- int not null default 500,
  acl_status INT NOT NULL DEFAULT 2,            -- int not null default 2,
  acl_group_memberships INT NOT NULL DEFAULT 0  -- int not null
);
INSERT INTO social_profile (profile_uid, profile_username, acl_group_memberships) VALUES
  (1,'root',1),
  (2,'tk',1);
CREATE TABLE social_group ( -- collection of profiles for a single purpose (e.g. engagement, event/activity etc.)
  group_id INT PRIMARY KEY,
  group_uid INT NOT NULL,
  group_type TEXT NOT NULL DEFAULT '',  -- e.g. “company”, “family”, “friends”, “hobbyists”, “activity”, 
  group_subtype TEXT NOT NULL DEFAULT '',  -- e.g. “accomplishment”, “concert”, “sport”, “party”, “activity”, ...
  group_title TEXT NOT NULL DEFAULT '',
  group_description TEXT NOT NULL DEFAULT '',
  group_parent_group_id INT NOT NULL DEFAULT 0,
  group_valid_time_start DATETIME NOT NULL DEFAULT 0,
  group_valid_time_end DATETIME NOT NULL DEFAULT 0,
  group_valid_time_repetition TEXT NOT NULL DEFAULT '',
  group_location_name TEXT NOT NULL DEFAULT '',
  group_location_city TEXT NOT NULL DEFAULT '',
  group_location_postcode TEXT NOT NULL DEFAULT '',
  group_location_street TEXT NOT NULL DEFAULT '',
  group_location_houseno TEXT NOT NULL DEFAULT '',
  group_location_details TEXT NOT NULL DEFAULT '',
  -- access control columns
  acl_owner INT NOT NULL DEFAULT 1,             -- int not null default 1,
  acl_group INT NOT NULL DEFAULT 1,             -- int not null default 1,
  acl_unixperms INT NOT NULL DEFAULT 500,       -- int not null default 500,
  acl_status INT NOT NULL DEFAULT 2             -- int not null default 2,
);
CREATE TABLE social_gp ( -- connects profiles to groups
  gp_profile_id INT NOT NULL DEFAULT 0,
  gp_group_id INT NOT NULL DEFAULT 0,
  gp_participates INT NOT NULL DEFAULT 0, -- 1/0
  gp_status TEXT NOT NULL DEFAULT '', -- “in” (the member added itself), “optout”, “out” (excluded by the group owner)
  qp_relation TEXT NOT NULL DEFAULT '' -- e.g. “moderator”, “participant”, ...
);
-- 2 down
DROP TABLE social_community;
DROP TABLE social_profile;
DROP TABLE social_group;
DROP TABLE social_gp;

-- 3 up
-- acl meta infos
CREATE TABLE acl_action (
  action_title TEXT PRIMARY KEY,               -- varchar(100) not null primary key,
  action_apply_object INT NOT NULL DEFAULT 1   -- tinyint      not null
);
INSERT INTO acl_action (action_title, action_apply_object) VALUES
  ('read',     1),
  ('write',    1),
  ('delete',   1),
  ('join',     1),
  ('activate', 1),
  ('passwd',   1),
  ('list_all', 0);
CREATE TABLE acl_implemented_action (
  implemented_action_table TEXT NOT NULL DEFAULT '',    -- varchar(100)    not null,
  implemented_action_action TEXT NOT NULL DEFAULT '',   -- varchar(100)    not null,
  implemented_action_status INT NOT NULL DEFAULT 0,     -- int             not null default 0,
  PRIMARY KEY (implemented_action_table, implemented_action_action)   
);
INSERT INTO acl_implemented_action (implemented_action_table, implemented_action_action, implemented_action_status) VALUES
  ('t_user',       'read',     0),
  ('t_user',       'write',    0),
  ('t_user',       'delete',   0),
  ('t_user',       'passwd',   0),
  ('t_event',      'read',     0),
  ('t_event',      'write',    0),
  ('t_event',      'delete',   0),
  ('t_event',      'join',     4),
  ('t_event',      'activate', 2),
  ('t_membership', 'read',     0),
  ('t_membership', 'write',    0),
  ('t_membership', 'delete',   0),
  ('t_membership', 'activate', 2);
CREATE TABLE acl_privilege (
  privilege_role TEXT NOT NULL DEFAULT '',           -- varchar(30)     not null default 'other',
  privilege_who INT NOT NULL DEFAULT 0,              -- int             not null default 0,
  privilege_action TEXT NOT NULL DEFAULT '',         -- varchar(100)    not null,
  privilege_type TEXT NOT NULL DEFAULT '',           -- varchar(30)     not null default '',
  privilege_related_table TEXT NOT NULL DEFAULT '',  -- varchar(100)    not null default '',
  privilege_related_uid INT NOT NULL DEFAULT 0,      -- int             not null default 0,
  PRIMARY KEY (privilege_role, privilege_who, privilege_action, privilege_type, 
	      privilege_related_table, privilege_related_uid)
);
INSERT INTO acl_privilege
      (privilege_role, privilege_who, privilege_action, privilege_type,
	privilege_related_table, privilege_related_uid) VALUES
  ('self',  0, 'passwd',   'object', 't_user',  0),
  ('group', 4, 'join',     'global', 't_event', 0),
  ('group', 4, 'list_all', 'table',  't_event', 0),
  ('user',  3, 'delete',   'object', 't_event', 1);
-- 3 down
DROP TABLE acl_action;
DROP TABLE acl_implemented_action;
DROP TABLE acl_privilege;
  
           
