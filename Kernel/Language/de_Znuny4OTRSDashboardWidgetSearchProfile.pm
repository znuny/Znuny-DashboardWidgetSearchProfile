# --
# Copyright (C) 2012-2022 Znuny GmbH, http://znuny.com/
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
    $Self->{Translation}->{'This configuration registers an OutputFilter module that shows the preference to save the profile for the dashboard or groups.'} = 'Diese Konfiguration registriert einen OutputFilter, um die Einstellung zur Speicherung des Suchprofils für das Dashboard oder Gruppe vorzunehmen.';

    $Self->{Translation}->{'Save search for dashboard'} = 'Suche für Dashboard speichern';
    $Self->{Translation}->{'Save search for group'} = 'Suche für Gruppe speichern';
    $Self->{Translation}->{'This configuration defines the groups which are able to define groups for search profiles.'} = 'Diese Konfiguration definiert Gruppen, welche berechtigt sind Gruppen für Suchprofile zu deifnieren.';
    $Self->{Translation}->{'This configuration defines the groups which permissions will be restricted to readonly in the dashboard view (no settings and filters for the widget).'} = 'Diese Konfiguration definiert Gruppen, deren Rechte auf Leserechte beschränkt werden in der Dashboard Übersicht (Keine Einstellungen und Filter für das Widget).';

    return 1;
}

1;
