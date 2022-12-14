# Konfiguration

Nach der Installation ist die Erweiterung ohne Konfiguration sofort nutzbar. Die angezeigten bzw. zur Verfügung stehenden Spalten sowie weitere Einstellungen können bei Bedarf angepasst werden.
Über die SysConfig-Option `DashboardBackend###0001-SearchProfile` erfolgt die Konfiguration des Widgets.

Jedem Agenten stehen seine persönlichen Suchvorlagen in der Ticketsuche zur Verfügung.

## Gruppenbasierte Vorlagen

Für jedes Suchprofil kann konfiguriert werden, dass es nicht nur für den Agenten selber, sondern auch für eine oder mehrere Gruppen zur Verfügung stehen soll.

Wird das Suchprofil beispielsweise der Gruppe "users" zugeordnet, erhalten alle dieser Gruppe zugehörigen Benutzer das Suchprofil. Das Profil steht den Nutzern nur lesend zur Verfügung.

Eine Bearbeitung des Profils ist nur durch einen Administrator möglich. Die Berechtigung für das Anlegen und Bearbeiten der gruppenbasierten Vorlagen kann über die SysConfig-Option `ZnunyDashboardWidgetSearchProfile::SearchProfile::Groups` konfiguriert werden.

## Dashboard nicht änderbar für spezielle Gruppen

Es gibt die Möglichkeit das Dashboard für bestimmte Gruppe nur lesbar und nicht veränderbar zu gestalten. Diese Gruppen können anschließend das Dashboard nur noch ansehen, besitzen aber keine
Möglichkeit die Einstellungen oder Filter des Widgets zu verändern. Hierfür muss die jeweilige Gruppe in die folgende SysConfig-Option eingetragen werden:

`ZnunyDashboardWidgetSearchProfile::SearchProfile::Groups::Readonly`

## Eingeloggte UserID in der Dashboard Konfiguration

In der SysConfig des Dashboards `DashboardBackend###0001-SearchProfile` können für die Suche im Wert "Attributes" Einschränkungen hinterlegt werden. Um die Suchattribute basierend
auf der UserID des aktuell eingeloggten Users aufzubauen kann man den Platzhalter `##UserID##` verwenden. Beispiel:

`StateType=open;ResponsibleIDs=##UserID##`

## Kürzung der Werte von dynamischen Feldern

Es gibt die Möglichkeit die Kürzung der dynamischen Feldwerte zu beeinflussen. Dazu muss der Wert `DynamicField_ValueMaxChars` der SysConfig `DashboardBackend###0001-SearchProfile` angepasst werden.

## Letzte Suche ausblenden

Aus Performance-Gründen kann es sinnvoll sein, die letzte Suche aus dem Dashboard auszublenden. Dazu muss der Wert `SearchProfile_LastSearch` der SysConfig `DashboardBackend###0001-SearchProfile` angepasst werden.
