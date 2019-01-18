# Configuration

After the installation, the extension can be used immediately without configuration. The displayed or available columns as well as other settings can be adjusted if necessary.
The SysConfig option `DashboardBackend ### 0001-SearchProfile` is used to configure the widget.

Each agent has access to his personal search templates for the ticket search.

## Group-based search templates

Each search profile can be configured to be available not only to the agent itself but also to the members of one or more groups.

If, for example, the search profile is assigned to the group "users", all users belonging to this group receive the search profile. The profile then is read-only for the users.

The profile can only be edited by an administrator. Authorization for creating and editing the group-based templates can be configured via the SysConfig option `Znuny4OTRSDashboardWidgetSearchProfile::SearchProfile::Groups`.

## Dashboard readonly for specific groups

There is a possibility to set the dashboard readonly and changeable for specific groups. These groups are not able to change the settings or filters of the dashboard afterwards.
For this functionality you just need to set the group name for the following SysConfig option:

`Znuny4OTRSDashboardWidgetSearchProfile::SearchProfile::Groups::Readonly`

## Logged-in user id in dashboard configuration

In the SysConfig of the dashboard `DashboardBackend###0001-SearchProfile` it is possible to set the base search attributes for the dasboard in the key "Attributes". To set the attributes
based on the current logged in user id it is possible to use the placeholder `##UserID`. Example:

`StateType=open;ResponsibleIDs=##UserID##`
