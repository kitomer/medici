package Medici::Helpers::ACL;

$permissions = array(
  "owner_read"   => 256,
  "owner_write"  => 128,
  "owner_delete" => 64,
  "group_read"   => 32,
  "group_write"  => 16,
  "group_delete" => 8,
  "other_read"   => 4,
  "other_write"  => 2,
  "other_delete" => 1
);
$groups = array(
  "root"          => 1,
  "officer"       => 2,
  "user"          => 4,
  "wheel"         => 8
);

sub all_object_priviledges {

  $obj_id      = 2;
  $tbl         = 't_user';
  $user_id     = 2;
  $user_groups = 4;
  $query = "
  select distinct ac.c_title
  from
    t_action as ac
    -- join onto the object itself
    inner join $tbl as obj on obj.c_uid = $obj_id
    -- Filter out actions that do not apply to this object type
    inner join t_implemented_action as ia
	on ia.c_action = ac.c_title
	  and ia.c_table = '$tbl'
	  and ((ia.c_status = 0) or (ia.c_status & obj.c_status <> 0))
    -- Privileges that apply to the object (or every object in the table)
    -- and grant the given action
    left outer join t_privilege as pr
	on pr.c_related_table = '$tbl'
	  and pr.c_action = ac.c_title
	  and (
	      (pr.c_type = 'object' and pr.c_related_uid = $obj_id)
	      or pr.c_type = 'global'
	      or (pr.c_role = 'self' and $user_id = $obj_id and '$tbl' = 't_user'))
  where
    -- The action must apply to objects
    ac.c_apply_object
    and (
	-- Members of the 'root' group are always allowed to do everything
	($user_groups & $groups[root] <> 0)
	-- UNIX style read permissions in the bit field
	or (ac.c_title = 'read' and (
	  -- The other_read permission bit is on
	  (obj.c_unixperms & $permissions[other_read] <> 0)
	  -- The owner_read permission bit is on, and the member is the owner
	  or ((obj.c_unixperms & $permissions[owner_read] <> 0)
	      and obj.c_owner = $user_id)
	  -- The group_read permission bit is on, and the member is in the group
	  or ((obj.c_unixperms & $permissions[group_read] <> 0)
	      and ($user_groups & obj.c_group <> 0))))
	-- UNIX style write permissions in the bit field
	or (ac.c_title = 'write' and (
	  -- The other_write permission bit is on
	  (obj.c_unixperms & $permissions[other_write] <> 0)
	  -- The owner_write permission bit is on, and the member is the owner
	  or ((obj.c_unixperms & $permissions[owner_write] <> 0)
	      and obj.c_owner = $user_id)
	  -- The group_write permission bit is on, and the member is in the group
	  or ((obj.c_unixperms & $permissions[group_write] <> 0)
	      and ($user_groups & obj.c_group <> 0))))
	-- UNIX style delete permissions in the bit field
	or (ac.c_title = 'delete' and (
	  -- The other_delete permission bit is on
	  (obj.c_unixperms & $permissions[other_delete] <> 0)
	  -- The owner_delete permission bit is on, and the member is the owner
	  or ((obj.c_unixperms & $permissions[owner_delete] <> 0)
	      and obj.c_owner = $user_id)
	  -- The group_delete permission bit is on, and the member is in the group
	  or ((obj.c_unixperms & $permissions[group_delete] <> 0)
	      and ($user_groups & obj.c_group <> 0))))
	-- user privileges
	or (pr.c_role = 'user' and pr.c_who = $user_id)
	-- owner privileges
	or (pr.c_role = 'owner' and obj.c_owner = $user_id)
	-- owner_group privileges
	or (pr.c_role = 'owner_group' and (obj.c_group & $user_groups <> 0))
	-- group privileges
	or (pr.c_role = 'group' and (pr.c_who & $user_groups <> 0)))
	-- self privileges
	or pr.c_role = 'self';
  ";
  echo $query;

}
    
sub all_actionable_objects {

  $tbl         = 't_event';
  $user_id     = 2;
  $user_groups = 4;
  $action      = 'join';
  $query = "
  select distinct obj.*
  from $tbl as obj
    -- Filter out actions that do not apply to this object type
    inner join t_implemented_action as ia
	on ia.c_table = '$tbl'
	  and ia.c_action = '$action'
	  and ((ia.c_status = 0) or (ia.c_status & obj.c_status <> 0))
    inner join t_action as ac
	on ac.c_title = '$action'
    -- Privileges that apply to the object (or every object in the table)
    -- and grant the given action
    left outer join t_privilege as pr
	on pr.c_related_table = '$tbl'
	  and pr.c_action = '$action'
	  and (
	      (pr.c_type = 'object' and pr.c_related_uid = obj.c_uid)
	      or pr.c_type = 'global'
	      or (pr.c_role = 'self' and $user_id = obj.c_uid and '$tbl' = 't_user'))
  where
    -- The action must apply to objects
    ac.c_apply_object
    and (
	-- Members of the 'root' group are always allowed to do everything
	($user_groups & $groups[root] <> 0)
	-- UNIX style read permissions in the bit field
	or (ac.c_title = 'read' and (
	  -- The other_read permission bit is on
	  (obj.c_unixperms & $permissions[other_read] <> 0)
	  -- The owner_read permission bit is on, and the member is the owner
	  or ((obj.c_unixperms & $permissions[owner_read] <> 0)
	      and obj.c_owner = $user_id)
	  -- The group_read permission bit is on, and the member is in the group
	  or ((obj.c_unixperms & $permissions[group_read] <> 0)
	      and ($user_groups & obj.c_group <> 0))))
	-- UNIX style write permissions in the bit field
	or (ac.c_title = 'write' and (
	  -- The other_write permission bit is on
	  (obj.c_unixperms & $permissions[other_write] <> 0)
	  -- The owner_write permission bit is on, and the member is the owner
	  or ((obj.c_unixperms & $permissions[owner_write] <> 0)
	      and obj.c_owner = $user_id)
	  -- The group_write permission bit is on, and the member is in the group
	  or ((obj.c_unixperms & $permissions[group_write] <> 0)
	      and ($user_groups & obj.c_group <> 0))))
	-- UNIX style delete permissions in the bit field
	or (ac.c_title = 'delete' and (
	  -- The other_delete permission bit is on
	  (obj.c_unixperms & $permissions[other_delete] <> 0)
	  -- The owner_delete permission bit is on, and the member is the owner
	  or ((obj.c_unixperms & $permissions[owner_delete] <> 0)
	      and obj.c_owner = $user_id)
	  -- The group_delete permission bit is on, and the member is in the group
	  or ((obj.c_unixperms & $permissions[group_delete] <> 0)
	      and ($user_groups & obj.c_group <> 0))))
	-- user privileges
	or (pr.c_role = 'user' and pr.c_who = $user_id)
	-- owner privileges
	or (pr.c_role = 'owner' and obj.c_owner = $user_id)
	-- owner_group privileges
	or (pr.c_role = 'owner_group' and (obj.c_group & $user_groups <> 0))
	-- group privileges
	or (pr.c_role = 'group' and (pr.c_who & $user_groups <> 0)))
	-- self privileges
	or pr.c_role = 'self';
  ";
  echo $query;
}
    
sub all_acl_entries {

  $obj_id      = 2;
  $tbl         = 't_user';
  $user_id     = 2;
  $user_groups = 4;
  $query = "
  select
      pr.c_role,
      pr.c_who,
      case
	  when (pr.c_role = 'user') then coalesce(us.c_username, '--DNE--')
	  when (pr.c_role = 'group') then ''
	  when (pr.c_role = 'owner_group') then ''
	  else 'none'
      end as c_name,
      pr.c_action,
      pr.c_type,
      pr.c_related_table as c_table,
      pr.c_related_uid,
      ia.c_status
  from t_privilege as pr
      inner join t_action as ac on ac.c_title = pr.c_action
      inner join $tbl as ob on ob.c_uid = $obj_id
      inner join t_implemented_action as ia on ia.c_table = '$tbl'
	  and ia.c_action = ac.c_title
      left outer join t_user as us
	  on pr.c_role = 'user'
	  and pr.c_who = us.c_uid
  where (
	  (pr.c_type = 'object' and pr.c_related_uid = $obj_id)
	  or (pr.c_type in ('table', 'global'))
	  or (pr.c_role = 'self' and pr.c_related_table = 't_user'))
      and pr.c_related_table = '$tbl'
  ";
  echo $query;
}
    
sub all-table-privileges {

  $tbl         = 't_event';
  $user_id     = 2;
  $user_groups = 4;
  $query = "
  select ac.c_title
  from
      t_action as ac
      -- Privileges that apply to the table and grant the given action
      -- Not an inner join because the action may be granted even if there is no
      -- privilege granting it.  For example, root users can take all actions.
      left outer join t_privilege as pr
	  on pr.c_related_table = '$tbl'
	      and pr.c_action = ac.c_title
	      and pr.c_type = 'table'
  where
      -- The action must apply to tables (NOT apply to objects)
      (ac.c_apply_object = 0) and (
	  -- Members of the 'root' group are always allowed to do everything
	  ($user_groups & $groups[root] <> 0)
	  -- user privileges
	  or (pr.c_role = 'user' and pr.c_who = $user_id)
	  -- group privileges
	  or (pr.c_role = 'group' and (pr.c_who & $user_groups <> 0)))
  ";
  echo $query;
}

1;
