# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::Znuny4OTRSDashboardWidgetSearchProfile;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Group',
    'Kernel::System::Log',
    'Kernel::System::SearchProfile',
    'Kernel::System::Web::Request',
);

use Kernel::System::VariableCheck qw(:all);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
    my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
    my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $LogObject           = $Kernel::OM->Get('Kernel::System::Log');
    my $ParamObject         = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $SearchProfileObject = $Kernel::OM->Get('Kernel::System::SearchProfile');

    # get group administrators
    my @SearchProfileGroupAdminList
        = @{ $ConfigObject->Get('Znuny4OTRSDashboardWidgetSearchProfile::SearchProfile::Groups') || [] };

    # get all groups
    my %Groups = $GroupObject->GroupList( Valid => 1 );

    # get checked status of the save dashboard checkbox
    my $SelectedGroupIDs      = [];
    my $SelectedSaveDashboard = '';
    my $Profile               = $ParamObject->GetParam( Param => 'Profile' ) || '';
    if ($Profile) {

        # get loaded profile
        my %SearchProfileData = $SearchProfileObject->SearchProfileGet(
            Base      => 'TicketSearch',
            Name      => $Profile,
            UserLogin => $LayoutObject->{UserLogin},
        );

        if (%SearchProfileData) {

            # set checkbox if dashboard is configured
            if ( $SearchProfileData{Znuny4OTRSSaveDashboard} ) {
                $SelectedSaveDashboard = ' checked="checked"';
            }

            # set list of selected groups
            if ( IsArrayRefWithData( $SearchProfileData{Znuny4OTRSSaveGroups} ) ) {
                $SelectedGroupIDs = $SearchProfileData{Znuny4OTRSSaveGroups};
            }
        }
    }

    # get user groups
    my %PermissionUserGetReverse = reverse $GroupObject->PermissionUserGet(
        UserID => $LayoutObject->{UserID},
        Type   => 'rw',
    );

    # check if the user is group admin
    my $IsAdmin = 0;
    GROUP:
    for my $Group (@SearchProfileGroupAdminList) {
        next GROUP if !$PermissionUserGetReverse{$Group};

        $IsAdmin = 1;

        last GROUP;
    }

    # prepare group selection
    my $SaveGroupsSelection = $LayoutObject->BuildSelection(
        Data         => \%Groups,
        Name         => 'SaveGroups',
        ID           => 'SaveGroups',
        Multiple     => 1,
        Size         => 1,
        Class        => 'Modernize',
        SelectedID   => $SelectedGroupIDs,
        Translation  => 1,
        PossibleNone => 1,
    );

    my $SaveDashboardLabel = $LayoutObject->{LanguageObject}->Translate('Save search for dashboard');
    my $SaveGroupsLabel    = $LayoutObject->{LanguageObject}->Translate('Save search for group');

    my $OptionsDashboardHTML = <<ZNUUNY;
            <div class="Clear"></div>
            <label>$SaveDashboardLabel:</label>
            <div class="Field">
                <input type="checkbox" name="SaveDashboard" id="SaveDashboard" value="1"$SelectedSaveDashboard />
            </div>
ZNUUNY
    my $OptionsSaveGroupsHTML = <<ZNUUNY;
            <div class="Clear"></div>
            <label>$SaveGroupsLabel:</label>
            <div class="Field">
                $SaveGroupsSelection
            </div>
ZNUUNY

    # get grouped search profiles
    my %SearchProfileGroupList = $SearchProfileObject->SearchProfileGroupList(
        Base      => 'TicketSearch',
        UserLogin => $LayoutObject->{UserLogin},
    );
    my $SearchProfilesGroupedJSON = $LayoutObject->JSONEncode(
        Data => \%SearchProfileGroupList,
    );

    # add js to have grouped search profiles available
    my $SearchProfilesGroupedHTML = <<JSBLOCK;
<script type="text/javascript">
Core.Config.Set('SearchProfilesGrouped', $SearchProfilesGroupedJSON);
Core.Config.Set('SearchProfileGroupAdmin', $IsAdmin);
</script>
JSBLOCK

    my $AddHTML = $SearchProfilesGroupedHTML . $OptionsDashboardHTML;
    if ($IsAdmin) {
        $AddHTML .= $OptionsSaveGroupsHTML;
    }

    # manipulate HTML content
    ${ $Param{Data} } =~ s{ <input [^>]+ SaveProfile [^>]+ > \s* <\/div> }{ $& $AddHTML }xmsi;

    return 1;
}

1;
