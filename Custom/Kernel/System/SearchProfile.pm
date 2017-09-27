# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# $origin: otrs - be4010f3365da552dcfd079c36ad31cc90e06c32 - Kernel/System/SearchProfile.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::ParamObject)

package Kernel::System::SearchProfile;

use strict;
use warnings;
# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
use Kernel::System::VariableCheck qw(:all);
# ---

# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
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

=head1 SYNOPSIS

module with all functions to manage search profiles

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $SearchProfileObject = $Kernel::OM->Get('Kernel::System::SearchProfile');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{DBObject} = $Kernel::OM->Get('Kernel::System::DB');

    $Self->{CacheType} = 'SearchProfile';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    # set lower if database is case sensitive
    $Self->{Lower} = '';
    if ( $Self->{DBObject}->GetDatabaseFunction('CaseSensitive') ) {
        $Self->{Lower} = 'LOWER';
    }

    return $Self;
}

=item SearchProfileAdd()

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
    for (qw(Base Name Key UserLogin)) {
        if ( !defined $Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }
# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
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

    for my $Value (@Data) {

        return if !$Self->{DBObject}->Do(
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
# Znuny4OTRS-DashboardWidgetSearchProfile
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

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get value for dashboard save state
    my $SaveDashboard = $ParamObject->GetParam( Param => 'SaveDashboard' ) || 0;
    my $Profile       = $ParamObject->GetParam( Param => 'Profile' )       || '';
    my $SaveProfile   = $ParamObject->GetParam( Param => 'SaveProfile' )   || 0;
    my @SaveGroups    = sort $ParamObject->GetArray(
        Param => 'SaveGroups',
    );

    return 1 if !$SaveProfile;
    return 1 if $Param{Base} ne 'TicketSearch';
    return 1 if $Profile ne $Param{Name};

    # get old profile if given
    my %SearchProfileData = $Self->SearchProfileGet(
        Base      => $Param{Base},
        Name      => $Param{Name},
        UserLogin => $Param{UserLogin},
    );
    return 1 if !%SearchProfileData;

    my $CurrentDashboardValue = $SearchProfileData{Znuny4OTRSSaveDashboard} || 0;
    if ( $CurrentDashboardValue != $SaveDashboard ) {

        # remove old key in profile if given
        if (%SearchProfileData) {
            $Self->SearchProfileDelete(
                Base      => $Param{Base},
                Name      => $Param{Name},
                Key       => 'Znuny4OTRSSaveDashboard',
                UserLogin => $Param{UserLogin},
            );
        }

        # save new value for dashboard show state
        $Self->SearchProfileAdd(
            Base      => $Param{Base},
            Name      => $Param{Name},
            Key       => 'Znuny4OTRSSaveDashboard',
            Value     => $SaveDashboard,
            UserLogin => $Param{UserLogin},
            Loop      => 1,
        );
    }

    my @CurrentGroups = sort @{ $SearchProfileData{Znuny4OTRSSaveGroups} || [] };
    my $GroupsDifferent = DataIsDifferent(
        Data1 => \@CurrentGroups,
        Data2 => \@SaveGroups,
    );
    if ($GroupsDifferent) {

        # remove old key in profile if given
        if (%SearchProfileData) {
            $Self->SearchProfileDelete(
                Base      => $Param{Base},
                Name      => $Param{Name},
                Key       => 'Znuny4OTRSSaveGroups',
                UserLogin => $Param{UserLogin},
            );
        }

        # save new value for dashboard show state
        $Self->SearchProfileAdd(
            Base      => $Param{Base},
            Name      => $Param{Name},
            Key       => 'Znuny4OTRSSaveGroups',
            Value     => \@SaveGroups,
            UserLogin => $Param{UserLogin},
            Loop      => 1,
        );
    }

# ---

    return 1;
}

=item SearchProfileGet()

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
    for (qw(Base Name UserLogin)) {
        if ( !defined( $Param{$_} ) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
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

    # get search profile
    return if !$Self->{DBObject}->Prepare(
        SQL => "
            SELECT profile_type, profile_key, profile_value
            FROM search_profile
            WHERE profile_name = ?
                AND $Self->{Lower}(login) = $Self->{Lower}(?)
            ",
        Bind => [ \$Param{Name}, \$Login ],
    );

    my %Result;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
        if ( $Data[0] eq 'ARRAY' ) {
            push @{ $Result{ $Data[1] } }, $Data[2];
        }
        else {
            $Result{ $Data[1] } = $Data[2];
        }
    }
# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
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
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---

=item SearchProfileGroupList()

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

    my %UserGroups = $GroupObject->PermissionUserGroupGet(
        UserID => $UserID,
        Type   => 'rw',
    );
    my @UserGroups = sort keys %UserGroups;
    return if !@UserGroups;

    my @GroupListQuoted;
    for my $Group (@UserGroups) {
        push @GroupListQuoted, $Self->{DBObject}->Quote($Group);
    }

    my $GroupListComma = "'" . join("','", @GroupListQuoted) . "'";
    my $SQLBase        = $Param{Base} . '%';

    my $SQLGroups = <<ZNUUNY;
    SELECT
        profile_name
    FROM
        search_profile
    WHERE
        profile_key = 'Znuny4OTRSSaveGroups' AND
        profile_value IN ($GroupListComma) AND
        login LIKE ?
ZNUUNY

    return if !$Self->{DBObject}->Prepare(
        SQL => $SQLGroups,
        Bind => [ \$SQLBase ],
    );

    my %Result;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
        $Result{ $Data[0] } = $Data[0];
    }

    return %Result;
}

=item SearchProfileGroupParamGet()

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

    my %UserGroups = $GroupObject->PermissionUserGroupGet(
        UserID => $UserID,
        Type   => 'rw',
    );
    my @UserGroups = sort keys %UserGroups;
    return if !@UserGroups;

    my @GroupListQuoted;
    for my $Group (@UserGroups) {
        push @GroupListQuoted, $Self->{DBObject}->Quote($Group);
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
        profile_key = 'Znuny4OTRSSaveGroups' AND
        profile_value IN ($GroupListComma) AND
        login LIKE ?
ZNUUNY

    return if !$Self->{DBObject}->Prepare(
        SQL => $SQLGroups,
        Bind => [ \$Param{Name}, \$SQLBase ],
    );

    my $Login;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
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

=item SearchProfileGroupGet()

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

=item SearchProfileDelete()

deletes a search profile.

    $SearchProfileObject->SearchProfileDelete(
        Base      => 'TicketSearch',
        Name      => 'last-search',
# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
        Key => 'abc',                      # optional
# ---
        UserLogin => 'me',
    );

=cut

sub SearchProfileDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Base Name UserLogin)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }
# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
    if ( !$Param{Loop} ) {
        my %SearchProfileGroupParamGet = $Self->SearchProfileGroupParamGet(%Param);
        if (%SearchProfileGroupParamGet) {
            $Self->SearchProfileDelete(
                %Param,
                %SearchProfileGroupParamGet,
                Loop => 1,
            );
        }
    }
# ---

    # create login string
    my $Login = $Param{Base} . '::' . $Param{UserLogin};

    # delete search profile
# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
#     return if !$Self->{DBObject}->Do(
#         SQL => "
#             DELETE
#             FROM search_profile
#             WHERE profile_name = ?
#                 AND $Self->{Lower}(login) = $Self->{Lower}(?)
#             ",
#         Bind => [ \$Param{Name}, \$Login ],
#     );

    if ( $Param{Key} ) {
        return if !$Self->{DBObject}->Do(
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
        return if !$Self->{DBObject}->Do(
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
# Znuny4OTRS-DashboardWidgetSearchProfile
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

=item SearchProfileList()

returns a hash of all profiles for the given user.

    my %SearchProfiles = $SearchProfileObject->SearchProfileList(
        Base      => 'TicketSearch',
        UserLogin => 'me',
    );

=cut

sub SearchProfileList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Base UserLogin)) {
        if ( !defined( $Param{$_} ) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
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

    # get search profile list
    return if !$Self->{DBObject}->Prepare(
        SQL => "
            SELECT profile_name
            FROM search_profile
            WHERE $Self->{Lower}(login) = $Self->{Lower}(?)
            ",
        Bind => [ \$Login ],
    );

    # fetch the result
    my %Result;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
        $Result{ $Data[0] } = $Data[0];
    }
# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
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

=item SearchProfileUpdateUserLogin()

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
    for (qw(Base UserLogin NewUserLogin)) {
        if ( !defined( $Param{$_} ) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
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
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
