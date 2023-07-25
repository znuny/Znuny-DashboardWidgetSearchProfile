# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2012 Znuny GmbH, https://znuny.com/
# --
# $origin: znuny - 4e84ea4bb19adae193fe08ab181211d0fc4b8a0a - Kernel/System/SearchProfile.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::ParamObject)

package Kernel::System::SearchProfile;

use strict;
use warnings;
# ---
# Znuny-DashboardWidgetSearchProfile
# ---
use Kernel::System::VariableCheck qw(:all);
# ---

# ---
# Znuny-DashboardWidgetSearchProfile
# ---
# our @ObjectDependencies = (
#     'Kernel::System::Cache',
#     'Kernel::System::DB',
#     'Kernel::System::Log',
# );
our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Group',
    'Kernel::System::Log',
    'Kernel::System::User',
    'Kernel::System::Web::Request',
);
# ---

=head1 NAME

Kernel::System::SearchProfile - module to manage search profiles

=head1 DESCRIPTION

module with all functions to manage search profiles

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $SearchProfileObject = $Kernel::OM->Get('Kernel::System::SearchProfile');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'SearchProfile';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    # set lower if database is case sensitive
    $Self->{Lower} = '';
    if ( $Kernel::OM->Get('Kernel::System::DB')->GetDatabaseFunction('CaseSensitive') ) {
        $Self->{Lower} = 'LOWER';
    }

    return $Self;
}

=head2 SearchProfileAdd()

to add a search profile item

    $SearchProfileObject->SearchProfileAdd(
        Base      => 'TicketSearch',
        Name      => 'last-search',
        Key       => 'Body',
        Value     => $String,    # SCALAR|ARRAYREF
        UserLogin => 123,
    );

=cut

sub SearchProfileAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Base Name Key UserLogin)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }
# ---
# Znuny-DashboardWidgetSearchProfile
# ---
    my %SearchProfileGroupParamGet = $Self->SearchProfileGroupParamGet(%Param);
    if (%SearchProfileGroupParamGet) {
        %Param = ( %Param, %SearchProfileGroupParamGet );
    }
# ---

    # check value
    return 1 if !defined $Param{Value};

    # create login string
    my $Login = $Param{Base} . '::' . $Param{UserLogin};

    my @Data;
    if ( ref $Param{Value} eq 'ARRAY' ) {
        @Data = @{ $Param{Value} };
        $Param{Type} = 'ARRAY';
    }
    else {
        @Data = ( $Param{Value} );
        $Param{Type} = 'SCALAR';
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    for my $Value (@Data) {

        return if !$DBObject->Do(
            SQL => "
                INSERT INTO search_profile
                (login, profile_name,  profile_type, profile_key, profile_value)
                VALUES (?, ?, ?, ?, ?)
                ",
            Bind => [
                \$Login, \$Param{Name}, \$Param{Type}, \$Param{Key}, \$Value,
            ],
        );
    }

# ---
# Znuny-DashboardWidgetSearchProfile
# ---
#     # reset cache
#     my $CacheKey = $Login . '::' . $Param{Name};
#     $Kernel::OM->Get('Kernel::System::Cache')->Delete(
#         Type => $Self->{CacheType},
#         Key  => $Login,
#     );
#     $Kernel::OM->Get('Kernel::System::Cache')->Delete(
#         Type => $Self->{CacheType},
#         Key  => $CacheKey,
#     );

    # remove full cache because of grouped search profiles
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    return 1 if $Param{Loop};

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get value for dashboard save state
    my $SaveDashboard  = $ParamObject->GetParam( Param => 'ShowInDashboardWidget' ) || 0;
    my $Profile        = $ParamObject->GetParam( Param => 'Profile' )                 || '';
    my $SaveProfile    = $ParamObject->GetParam( Param => 'SaveProfile' )             || 0;
    my $TakeLastSearch = $ParamObject->GetParam( Param => 'TakeLastSearch' )          || 0;
    my @NewGroups      = sort $ParamObject->GetArray(
        Param => 'ProfileGroupIDs',
    );

    return 1 if !$SaveProfile;
    return 1 if $Param{Base} ne 'TicketSearch';
    return 1 if $Profile ne $Param{Name};
    return 1 if $TakeLastSearch;

    # get old profile if given
    my %SearchProfileData = $Self->SearchProfileGet(
        Base      => $Param{Base},
        Name      => $Param{Name},
        UserLogin => $Param{UserLogin},
    );
    return 1 if !%SearchProfileData;

    my $CurrentDashboardValue = $SearchProfileData{ShowInDashboardWidget} || 0;
    if ( $CurrentDashboardValue != $SaveDashboard ) {

        # remove old key in profile if given
        if (%SearchProfileData) {
            $Self->SearchProfileDelete(
                Base      => $Param{Base},
                Name      => $Param{Name},
                Key       => 'ShowInDashboardWidget',
                UserLogin => $Param{UserLogin},
            );
        }

        # save new value for dashboard show state
        $Self->SearchProfileAdd(
            Base      => $Param{Base},
            Name      => $Param{Name},
            Key       => 'ShowInDashboardWidget',
            Value     => $SaveDashboard,
            UserLogin => $Param{UserLogin},
            Loop      => 1,
        );
    }

    my @CurrentGroups = sort @{ $SearchProfileData{ProfileGroupIDs} || [] };
    my $GroupsDifferent = DataIsDifferent(
        Data1 => \@CurrentGroups,
        Data2 => \@NewGroups,
    );
    if ($GroupsDifferent) {

        # remove old key in profile if given
        if (%SearchProfileData) {
            $Self->SearchProfileDelete(
                Base      => $Param{Base},
                Name      => $Param{Name},
                Key       => 'ProfileGroupIDs',
                UserLogin => $Param{UserLogin},
            );
        }

        # save new value for dashboard show state
        $Self->SearchProfileAdd(
            Base      => $Param{Base},
            Name      => $Param{Name},
            Key       => 'ProfileGroupIDs',
            Value     => \@NewGroups,
            UserLogin => $Param{UserLogin},
            Loop      => 1,
        );
    }

    $CacheObject->CleanUp(
        Type => 'Dashboard',
    );
# ---

    return 1;
}

=head2 SearchProfileGet()

returns hash with search profile.

    my %SearchProfileData = $SearchProfileObject->SearchProfileGet(
        Base      => 'TicketSearch',
        Name      => 'last-search',
        UserLogin => 'me',
    );

=cut

sub SearchProfileGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Base Name UserLogin)) {
        if ( !defined( $Param{$Needed} ) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # create login string
    my $Login = $Param{Base} . '::' . $Param{UserLogin};

    # check the cache
    my $CacheKey = $Login . '::' . $Param{Name};
    my $Cache    = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    return %{$Cache} if $Cache;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get search profile
    return if !$DBObject->Prepare(
        SQL => "
            SELECT profile_type, profile_key, profile_value
            FROM search_profile
            WHERE profile_name = ?
                AND $Self->{Lower}(login) = $Self->{Lower}(?)
            ",
        Bind => [ \$Param{Name}, \$Login ],
    );

    my %Result;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        if ( $Data[0] eq 'ARRAY' ) {
            push @{ $Result{ $Data[1] } }, $Data[2];
        }
        else {
            $Result{ $Data[1] } = $Data[2];
        }
    }
# ---
# Znuny-DashboardWidgetSearchProfile
# ---
    if ( !$Param{Loop} ) {
        my %SearchProfileGroupGet = $Self->SearchProfileGroupGet(%Param);
        if (%SearchProfileGroupGet) {
            %Result = %SearchProfileGroupGet;
        }
    }
# ---
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \%Result
    );

    return %Result;
}
# ---
# Znuny-DashboardWidgetSearchProfile
# ---

=head2 SearchProfileGroupList()

returns hash with search profile parameter for SearchProfileGet.

    my %SearchProfileGroupList = $SearchProfileObject->SearchProfileGroupList(
        Base      => 'TicketSearch',
        UserLogin => 'me',
    );

=cut

sub SearchProfileGroupList {
    my ( $Self, %Param ) = @_;

    my $UserObject  = $Kernel::OM->Get('Kernel::System::User');
    my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Base UserLogin)) {
        next NEEDED if $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need $Needed!"
        );
        return;
    }

    my $UserID = $UserObject->UserLookup(
        UserLogin => $Param{UserLogin},
    );
    return if !$UserID;

    my %UserGroups = $GroupObject->PermissionUserGet(
        UserID => $UserID,
        Type   => 'rw',
    );

    my @UserGroups = sort keys %UserGroups;
    return if !@UserGroups;

    my @GroupListQuoted;
    for my $Group (@UserGroups) {
        push @GroupListQuoted, $DBObject->Quote($Group);
    }

    my $GroupListComma = "'" . join("','", @GroupListQuoted) . "'";
    my $SQLBase        = $Param{Base} . '%';

    my $SQLGroups = <<ZNUUNY;
    SELECT
        profile_name
    FROM
        search_profile
    WHERE
        profile_key = 'ProfileGroupIDs' AND
        profile_value IN ($GroupListComma) AND
        login LIKE ?
ZNUUNY

    return if !$DBObject->Prepare(
        SQL => $SQLGroups,
        Bind => [ \$SQLBase ],
    );

    my %Result;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $Result{ $Data[0] } = $Data[0];
    }

    return %Result;
}

=head2 SearchProfileGroupParamGet()

returns hash with search profile parameter for SearchProfileGet.

    my %SearchProfileGroupParamGet = $SearchProfileObject->SearchProfileGroupParamGet(
        Base      => 'TicketSearch',
        Name      => 'last-search',
        UserLogin => 'me',
    );

=cut

sub SearchProfileGroupParamGet {
    my ( $Self, %Param ) = @_;

    my $UserObject  = $Kernel::OM->Get('Kernel::System::User');
    my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Base Name UserLogin)) {
        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need $Needed!"
        );
        return;
    }

    my $UserID = $UserObject->UserLookup(
        UserLogin => $Param{UserLogin},
    );
    return if !$UserID;

    my %UserGroups = $GroupObject->PermissionUserGet(
        UserID => $UserID,
        Type   => 'rw',
    );
    my @UserGroups = sort keys %UserGroups;
    return if !@UserGroups;

    my @GroupListQuoted;
    for my $Group (@UserGroups) {
        push @GroupListQuoted, $DBObject->Quote($Group);
    }

    my $GroupListComma = "'" . join("','", @GroupListQuoted) . "'";
    my $SQLBase        = $Param{Base} . '%';

    my $SQLGroups = <<ZNUUNY;
    SELECT
        login
    FROM
        search_profile
    WHERE
        profile_name = ? AND
        profile_key = 'ProfileGroupIDs' AND
        profile_value IN ($GroupListComma) AND
        login LIKE ?
ZNUUNY

    return if !$DBObject->Prepare(
        SQL => $SQLGroups,
        Bind => [ \$Param{Name}, \$SQLBase ],
    );

    my $Login;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $Login = $Data[0];
    }
    return if !$Login;

    my ($Base, $UserLogin) = split /\:\:/, $Login;

    return (
        Base      => $Base,
        Name      => $Param{Name},
        UserLogin => $UserLogin,
        Loop      => 1,
    );
}

=head2 SearchProfileGroupGet()

returns hash with search profile.

    my %SearchProfileGroupGet = $SearchProfileObject->SearchProfileGroupGet(
        Base      => 'TicketSearch',
        Name      => 'last-search',
        UserLogin => 'me',
    );

=cut

sub SearchProfileGroupGet {
    my ( $Self, %Param ) = @_;

    # get parameter for group search profile if exists
    my %SearchProfileGroupParamGet = $Self->SearchProfileGroupParamGet(%Param);
    return if !%SearchProfileGroupParamGet;

    my %SearchProfileData = $Self->SearchProfileGet(%SearchProfileGroupParamGet);
    return %SearchProfileData;
}
# ---

=head2 SearchProfileDelete()

deletes a search profile.

    $SearchProfileObject->SearchProfileDelete(
        Base      => 'TicketSearch',
        Name      => 'last-search',
# ---
# Znuny-DashboardWidgetSearchProfile
# ---
        Key => 'abc',                      # optional
# ---
        UserLogin => 'me',
    );

=cut

sub SearchProfileDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Base Name UserLogin)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }
# ---
# Znuny-DashboardWidgetSearchProfile
# ---
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    if ( !$Param{Loop} ) {
        my %SearchProfileGroupParamGet = $Self->SearchProfileGroupParamGet(%Param);
        if (%SearchProfileGroupParamGet) {
            $Self->SearchProfileDelete(
                %Param,
                %SearchProfileGroupParamGet,
                Loop => 1,
            );

            $CacheObject->CleanUp(
                Type => 'Dashboard',
            );
        }
    }
# ---

    # create login string
    my $Login = $Param{Base} . '::' . $Param{UserLogin};

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # delete search profile
# ---
# Znuny-DashboardWidgetSearchProfile
# ---
#     return if !$DBObject->Do(
#         SQL => "
#             DELETE
#             FROM search_profile
#             WHERE profile_name = ?
#                 AND $Self->{Lower}(login) = $Self->{Lower}(?)
#             ",
#         Bind => [ \$Param{Name}, \$Login ],
#     );

    if ( $Param{Key} ) {
        return if !$DBObject->Do(
            SQL => "
                DELETE
                FROM search_profile
                WHERE profile_name = ?
                    AND $Self->{Lower}(login) = $Self->{Lower}(?)
                    AND profile_key = ?
                ",
            Bind => [ \$Param{Name}, \$Login, \$Param{Key} ],
        );
    }
    else {
        return if !$DBObject->Do(
            SQL => "
                DELETE
                FROM search_profile
                WHERE profile_name = ?
                    AND $Self->{Lower}(login) = $Self->{Lower}(?)
                ",
            Bind => [ \$Param{Name}, \$Login ],
        );
    }
# ---

# ---
# Znuny-DashboardWidgetSearchProfile
# ---
#     # delete cache
#     my $CacheKey = $Login . '::' . $Param{Name};
#     $Kernel::OM->Get('Kernel::System::Cache')->Delete(
#         Type => $Self->{CacheType},
#         Key  => $Login,
#     );
#     $Kernel::OM->Get('Kernel::System::Cache')->Delete(
#         Type => $Self->{CacheType},
#         Key  => $CacheKey,
#     );

    # remove full cache because of grouped search profiles
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );
# ---

    return 1;
}

=head2 SearchProfileList()

returns a hash of all profiles for the given user.

    my %SearchProfiles = $SearchProfileObject->SearchProfileList(
        Base      => 'TicketSearch',
        UserLogin => 'me',
    );

=cut

sub SearchProfileList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Base UserLogin)) {
        if ( !defined( $Param{$Needed} ) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # create login string
    my $Login = $Param{Base} . '::' . $Param{UserLogin};

    my $Cache = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $Login,
    );
    return %{$Cache} if $Cache;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get search profile list
    return if !$DBObject->Prepare(
        SQL => "
            SELECT profile_name
            FROM search_profile
            WHERE $Self->{Lower}(login) = $Self->{Lower}(?)
            ",
        Bind => [ \$Login ],
    );

    # fetch the result
    my %Result;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $Result{ $Data[0] } = $Data[0];
    }
# ---
# Znuny-DashboardWidgetSearchProfile
# ---
    my %SearchProfileGroupList = $Self->SearchProfileGroupList(%Param);
    if (%SearchProfileGroupList) {
        %Result = ( %Result, %SearchProfileGroupList );
    }
# ---
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $Login,
        Value => \%Result,
    );

    return %Result;
}

=head2 SearchProfileUpdateUserLogin()

changes the UserLogin of SearchProfiles

    my $Result = $SearchProfileObject->SearchProfileUpdateUserLogin(
        Base         => 'TicketSearch',
        UserLogin    => 'me',
        NewUserLogin => 'newme',
    );

=cut

sub SearchProfileUpdateUserLogin {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Base UserLogin NewUserLogin)) {
        if ( !defined( $Param{$Needed} ) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # get existing profiles
    my %SearchProfiles = $Self->SearchProfileList(
        Base      => $Param{Base},
        UserLogin => $Param{UserLogin},
    );

    # iterate over profiles; create them for new login name and delete old ones
    for my $SearchProfile ( sort keys %SearchProfiles ) {
        my %Search = $Self->SearchProfileGet(
            Base      => $Param{Base},
            Name      => $SearchProfile,
            UserLogin => $Param{UserLogin},
        );

        # add profile for new login (needs to be done per attribute)
        for my $Attribute ( sort keys %Search ) {
            $Self->SearchProfileAdd(
                Base      => $Param{Base},
                Name      => $SearchProfile,
                Key       => $Attribute,
                Value     => $Search{$Attribute},
                UserLogin => $Param{NewUserLogin},
            );
        }

        # delete the old profile
        $Self->SearchProfileDelete(
            Base      => $Param{Base},
            Name      => $SearchProfile,
            UserLogin => $Param{UserLogin},
        );
    }

    return 1;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
