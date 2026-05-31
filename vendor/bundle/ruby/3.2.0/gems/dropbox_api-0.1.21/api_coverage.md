# @title API Implementation Coverage

The Dropbox API changes frequently, so you may find out that the feature that
you need is missing. This document indicates what endpoints have been
implemented.

Full moon means fully implemented. Half moon means that the basic functionality
of the endpoint has been implemented but some options may be missing. Guess
what new moon means.

## File properties

API call | Status
--- | :---:
`/properties/add` | 🌑
`/properties/overwrite` | 🌑
`/properties/remove` | 🌑
`/properties/search` | 🌑
`/properties/search/continue` | 🌑
`/properties/update` | 🌑
`/templates/add_for_user` | 🌑
`/templates/get_for_user` | 🌑
`/templates/list_for_user` | 🌑
`/templates/remove_for_user` | 🌑
`/templates/update_for_user` | 🌑

## File requests

API call | Status
--- | :---:
`/create` | 🌕
`/get` | 🌑
`/list` | 🌑
`/update` | 🌑

## Files

API call | Status
--- | :---:
`/copy` | 🌕
`/copy_batch` | 🌕
`/copy_batch/check` | 🌕
`/copy_reference/get` | 🌕
`/copy_reference/save` | 🌕
`/create_folder` | 🌕
`/create_folder_batch` | 🌕
`/create_folder_batch/check` | 🌕
`/delete` | 🌕
`/delete_batch` | 🌕
`/delete_batch/check` | 🌕
`/download` | 🌔
`/download_zip` | 🌑
`/get_metadata` | 🌕
`/get_preview` | 🌕
`/get_temporary_link` | 🌕
`/get_temporary_upload_link` | 🌑
`/get_thumbnail` | 🌕
`/get_thumbnail_batch` | 🌑
`/list_folder` | 🌕
`/list_folder/continue` | 🌕
`/list_folder/get_latest_cursor` | 🌕
`/list_folder/longpoll` | 🌕
`/list_revisions` | 🌕
`/move` | 🌕
`/move_batch` | 🌑
`/move_batch/check` | 🌑
`/permanently_delete` | 🌕
`/restore` | 🌕
`/save_url` | 🌕
`/save_url/check_job_status` | 🌕
`/search_v2` | 🌔
`/upload` | 🌕
`/upload_session/append` | alias?
`/upload_session/append_v2` | 🌕
`/upload_session/finish` | 🌕
`/upload_session/finish_batch` | 🌑
`/upload_session/finish_batch/check` | 🌑
`/upload_session/start` | 🌕

## Paper

API call | Status
--- | :---:
`/docs/archive` | 🌑
`/docs/create` | 🌑
`/docs/download` | 🌑
`/docs/folder_users/list` | 🌑
`/docs/folder_users/list/continue` | 🌑
`/docs/get_folder_info` | 🌑
`/docs/list` | 🌑
`/docs/list/continue` | 🌑
`/docs/permanently_delete` | 🌑
`/docs/sharing_policy/get` | 🌑
`/docs/sharing_policy/set` | 🌑
`/docs/update` | 🌑
`/docs/users/add` | 🌑
`/docs/users/list` | 🌑
`/docs/users/list/continue` | 🌑
`/docs/users/remove` | 🌑

## Sharing

API call | Status
--- | :---:
`/add_file_member` | 🌕
`/add_folder_member` | 🌕
`/check_job_status` | 🌑
`/check_remove_member_job_status` | 🌑
`/check_share_job_status` | 🌑
`/create_shared_link_with_settings` | 🌓
`/get_file_metadata` | 🌑
`/get_file_metadata/batch` | 🌑
`/get_folder_metadata` | 🌑
`/get_shared_link_file` | 🌑
`/get_shared_link_metadata` | 🌔
`/list_file_members` | 🌕
`/list_file_members/batch` | 🌑
`/list_file_members/continue` | 🌑
`/list_folder_members` | 🌕
`/list_folder_members/continue` | 🌑
`/list_folders` | 🌑
`/list_folders/continue` | 🌑
`/list_mountable_folders` | 🌑
`/list_mountable_folders/continue` | 🌑
`/list_received_files` | 🌑
`/list_received_files/continue` | 🌑
`/list_shared_links` | 🌕
`/modify_shared_link_settings` | 🌑
`/mount_folder` | 🌑
`/relinquish_file_membership` | 🌑
`/relinquish_folder_membership` | 🌑
`/remove_file_member_2` | 🌑
`/remove_folder_member` | 🌑
`/revoke_shared_link` | 🌕
`/set_access_inheritance` | 🌑
`/share_folder` | 🌕
`/transfer_folder` | 🌑
`/unmount_folder` | 🌑
`/unshare_file` | 🌕
`/unshare_folder` | 🌑
`/update_file_member` | 🌑
`/update_folder_member` | 🌑
`/update_folder_policy` | 🌑

## Users

API call | Status
--- | :---:
`/get_account` | 🌕
`/get_account_batch` | 🌕
`/get_current_account` | 🌕
`/get_space_usage` | 🌕

## Dropbox Business API

Unfortunately, none of the Dropbox Business endpoints have been implemented.
If this is a problem for you, please [open an
issue](https://github.com/Jesus/dropbox_api/issues/new).
