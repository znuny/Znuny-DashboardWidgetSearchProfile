# --
# Copyright (C) 2012 Znuny GmbH, https://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package var::packagesetup::ZnunyDashboardWidgetSearchProfile;    ## no critic

use strict;
use warnings;

use utf8;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::SysConfig',
    'Kernel::System::ZnunyHelper',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

var::packagesetup::ZnunyDashboardWidgetSearchProfile - code to execute during package installation

=head1 SYNOPSIS

All code to execute during package installation

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $CodeObject = $Kernel::OM->Get('var::packagesetup::ZnunyDashboardWidgetSearchProfile');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
    $ZnunyHelperObject->_RebuildConfig();

    return $Self;
}

=head2 CodeInstall()

run the code install part

    my $Result = $CodeObject->CodeInstall();

=cut

sub CodeInstall {
    my ( $Self, %Param ) = @_;

    return if !$Self->_EnableDashboardSearchProfileDynamicFieldSelection(%Param);
    return if !$Self->_MigrateSearchProfileKeys(%Param);
    return if !$Self->_MigrateSysConfigSettings(%Param);

    return 1;
}

=head2 CodeReinstall()

run the code reinstall part

    my $Result = $CodeObject->CodeReinstall();

=cut

sub CodeReinstall {
    my ( $Self, %Param ) = @_;

    return if !$Self->_EnableDashboardSearchProfileDynamicFieldSelection(%Param);
    return if !$Self->CodeUninstall();
    return if !$Self->CodeInstall();

    return 1;
}

=head2 CodeUpgrade()

run the code upgrade part

    my $Result = $CodeObject->CodeUpgrade();

=cut

sub CodeUpgrade {
    my ( $Self, %Param ) = @_;

    return if !$Self->_EnableDashboardSearchProfileDynamicFieldSelection(%Param);
    return if !$Self->CodeInstall();

    return 1;
}

=head2 CodeUninstall()

run the code uninstall part

    my $Result = $CodeObject->CodeUninstall();

=cut

sub CodeUninstall {
    my ( $Self, %Param ) = @_;

    return if !$Self->_DisableDashboardSearchProfileDynamicFieldSelection(%Param);

    return 1;
}

=head2 _EnableDashboardSearchProfileDynamicFieldSelection()

Enables selection of dynamic fields via AdminDynamicFieldScreenConfiguration for dashboard widget SearchProfile.

=cut

sub _EnableDashboardSearchProfileDynamicFieldSelection {
    my ( $Self, %Param ) = @_;

    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    my $DefaultColumnsScreens = $ConfigObject->Get('DefaultColumnsScreens') // {};

    if (
        exists $DefaultColumnsScreens->{Framework}
        && !exists $DefaultColumnsScreens->{Framework}->{'DashboardBackend###0001-SearchProfile'}
        )
    {
        $DefaultColumnsScreens->{Framework}->{'DashboardBackend###0001-SearchProfile'}
            = 'DashboardWidget SearchProfile';

        my $SysConfigOptionSet = $SysConfigObject->SettingsSet(
            UserID   => 1,
            Comments => 'CodeInstall of Znuny-DashboardWidgetSearchProfile',
            Settings => [
                {
                    Name           => 'DefaultColumnsScreens###Framework',
                    EffectiveValue => $DefaultColumnsScreens->{Framework},
                },
            ],
        );

        return if !$SysConfigOptionSet;
    }

    my $ConfigKeysOfScreensByObjectType
        = $ConfigObject->Get('DynamicFields::ScreenConfiguration::ConfigKeysOfScreensByObjectType') // {};

    if (
        exists $ConfigKeysOfScreensByObjectType->{Framework}
        && !exists $ConfigKeysOfScreensByObjectType->{Framework}->{Ticket}->{'DashboardBackend###0001-SearchProfile'}
        )
    {
        $ConfigKeysOfScreensByObjectType->{Framework}->{Ticket}->{'DashboardBackend###0001-SearchProfile'}
            = 'DashboardWidget SearchProfile';

        my $SysConfigOptionSet = $SysConfigObject->SettingsSet(
            UserID   => 1,
            Comments => 'CodeInstall of Znuny-DashboardWidgetSearchProfile',
            Settings => [
                {
                    Name           => 'DynamicFields::ScreenConfiguration::ConfigKeysOfScreensByObjectType###Framework',
                    EffectiveValue => $ConfigKeysOfScreensByObjectType->{Framework},
                },
            ],
        );

        return if !$SysConfigOptionSet;
    }

    return 1;
}

=head2 _DisableDashboardSearchProfileDynamicFieldSelection()

Disables selection of dynamic fields via AdminDynamicFieldScreenConfiguration for dashboard widget SearchProfile.

=cut

sub _DisableDashboardSearchProfileDynamicFieldSelection {
    my ( $Self, %Param ) = @_;

    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    my $DefaultColumnsScreens = $ConfigObject->Get('DefaultColumnsScreens') // {};

    if (
        exists $DefaultColumnsScreens->{Framework}
        && exists $DefaultColumnsScreens->{Framework}->{'DashboardBackend###0001-SearchProfile'}
        )
    {

        delete $DefaultColumnsScreens->{Framework}->{'DashboardBackend###0001-SearchProfile'};

        my $SysConfigOptionSet = $SysConfigObject->SettingsSet(
            UserID   => 1,
            Comments => 'CodeInstall of Znuny-DashboardWidgetSearchProfile',
            Settings => [
                {
                    Name           => 'DefaultColumnsScreens###Framework',
                    EffectiveValue => $DefaultColumnsScreens->{Framework},
                },
            ],
        );

        return if !$SysConfigOptionSet;
    }

    my $ConfigKeysOfScreensByObjectType
        = $ConfigObject->Get('DynamicFields::ScreenConfiguration::ConfigKeysOfScreensByObjectType') // {};

    if (
        exists $ConfigKeysOfScreensByObjectType->{Framework}
        && exists $ConfigKeysOfScreensByObjectType->{Framework}->{Ticket}->{'DashboardBackend###0001-SearchProfile'}
        )
    {
        delete $ConfigKeysOfScreensByObjectType->{Framework}->{Ticket}->{'DashboardBackend###0001-SearchProfile'};

        my $SysConfigOptionSet = $SysConfigObject->SettingsSet(
            UserID   => 1,
            Comments => 'CodeInstall of Znuny-DashboardWidgetSearchProfile',
            Settings => [
                {
                    Name           => 'DynamicFields::ScreenConfiguration::ConfigKeysOfScreensByObjectType###Framework',
                    EffectiveValue => $ConfigKeysOfScreensByObjectType->{Framework},
                },
            ],
        );

        return if !$SysConfigOptionSet;
    }

    return 1;
}

=head2 _MigrateSearchProfileKeys()

Migrates search profile keys to 6.3.

    $CodeObject->_MigrateSearchProfileKeys();

=cut

sub _MigrateSearchProfileKeys {
    my ( $Self, %Param ) = @_;

    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    my %SearchProfileKeyMapping = (
        Znuny4OTRSSaveDashboard => 'ShowInDashboardWidget',
        Znuny4OTRSSaveGroups    => 'ProfileGroupIDs',
    );

    for my $OldSearchProfileKey ( sort keys %SearchProfileKeyMapping ) {
        my $NewSearchProfileKey = $SearchProfileKeyMapping{$OldSearchProfileKey};

        my $SQL = '
            UPDATE search_profile
            SET    profile_key = ?
            WHERE  profile_key = ?
        ';

        my @Bind = (
            \$NewSearchProfileKey,
            \$OldSearchProfileKey,
        );

        return if !$DBObject->Do(
            SQL  => $SQL,
            Bind => \@Bind,
        );
    }

    $CacheObject->CleanUp(
        Type => 'Dashboard',
    );
    $CacheObject->CleanUp(
        Type => 'SearchProfile',
    );

    return 1;
}

=head2 _MigrateSysConfigSettings()

Migrates SysConfig settings to 6.3.

    $CodeObject->_MigrateSysConfigSettings();

=cut

sub _MigrateSysConfigSettings {
    my ( $Self, %Param ) = @_;

    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my $SysConfigObject   = $Kernel::OM->Get('Kernel::System::SysConfig');
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
    my $LogObject         = $Kernel::OM->Get('Kernel::System::Log');

    my $UserID = 1;

    my %RenamedSysConfigOptions = (
        'Znuny4OTRSDashboardWidgetSearchProfile::SearchProfile::Groups' => [
            'ZnunyDashboardWidgetSearchProfile::SearchProfile::Groups',
        ],
        'Znuny4OTRSDashboardWidgetSearchProfile::SearchProfile::Groups::Readonly' => [
            'ZnunyDashboardWidgetSearchProfile::SearchProfile::Groups::Readonly',
        ],
    );

    ORIGINALSYSCONFIGOPTIONNAME:
    for my $OriginalSysConfigOptionName ( sort keys %RenamedSysConfigOptions ) {

        # Fetch original SysConfig option value.
        my ( $OriginalSysConfigOptionBaseName, @OriginalSysConfigOptionHashKeys ) = split '###',
            $OriginalSysConfigOptionName;

        my $OriginalSysConfigOptionValue = $ConfigObject->Get($OriginalSysConfigOptionBaseName);
        next ORIGINALSYSCONFIGOPTIONNAME if !defined $OriginalSysConfigOptionValue;

        if (@OriginalSysConfigOptionHashKeys) {
            for my $OriginalSysConfigOptionHashKey (@OriginalSysConfigOptionHashKeys) {
                next ORIGINALSYSCONFIGOPTIONNAME if ref $OriginalSysConfigOptionValue ne 'HASH';
                next ORIGINALSYSCONFIGOPTIONNAME
                    if !exists $OriginalSysConfigOptionValue->{$OriginalSysConfigOptionHashKey};

                $OriginalSysConfigOptionValue = $OriginalSysConfigOptionValue->{$OriginalSysConfigOptionHashKey};
            }
        }
        next ORIGINALSYSCONFIGOPTIONNAME if !defined $OriginalSysConfigOptionValue;

        my $NewSysConfigOptionNames = $RenamedSysConfigOptions{$OriginalSysConfigOptionName};
        for my $NewSysConfigOptionName ( @{$NewSysConfigOptionNames} ) {
            my $SettingUpdated = $SysConfigObject->SettingsSet(
                Settings => [
                    {
                        Name           => $NewSysConfigOptionName,
                        IsValid        => 1,
                        EffectiveValue => $OriginalSysConfigOptionValue,
                    },
                ],
                UserID => $UserID,
            );

            next ORIGINALSYSCONFIGOPTIONNAME if $SettingUpdated;

            $LogObject->Log(
                Priority => 'error',
                Message =>
                    "Error: Unable to migrate value of SysConfig option $OriginalSysConfigOptionName to option $NewSysConfigOptionName",
            );
        }
    }

    $ZnunyHelperObject->_RebuildConfig();

    return 1;
}

1;
