# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_Znuny4OTRSDashboardWidgetSearchProfile;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Search Profiles'} = 'Suchvorlagen';
    $Self->{Translation}->{'Available search profiles of the current agent'} = 'Verfügbare Suchvorlagen des momentanen Agenten';

    return 1;
}

1;
