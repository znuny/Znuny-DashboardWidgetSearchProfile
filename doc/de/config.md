# Konfiguration

Nach der Installation ist die Erweiterung ohne Konfiguration sofort nutzbar. Die angezeigten bzw. zur Verfügung stehenden Spalten sowie weitere Einstellungen können bei Bedarf angepasst werden.
Über die SysConfig-Option `DashboardBackend###0001-SearchProfile` erfolgt die Konfiguration des Widgets.

Jedem Agenten stehen seine persönlichen Suchvorlagen in der Ticketsuche zur Verfügung.

## Gruppenbasierte Vorlagen

Für jedes Suchprofil kann konfiguriert werden, dass es nicht nur für den Agenten selber, sondern auch für eine oder mehrere Gruppen zur Verfügung stehen soll.

Wird das Suchprofil beispielsweise der Gruppe "users" zugeordnet, erhalten alle dieser Gruppe zugehörigen Benutzer das Suchprofil. Das Profil steht den Nutzern nur lesend zur Verfügung.

Eine Bearbeitung des Profils ist nur durch einen Administrator möglich. Die Berechtigung für das Anlegen und Bearbeiten der gruppenbasierten Vorlagen kann über die SysConfig-Option `Znuny4OTRSDashboardWidgetSearchProfile::SearchProfile::Groups` konfiguriert werden.

## Dashboard nicht änderbar für spezielle Gruppen

Es gibt die Möglichkeit das Dashboard für bestimmte Gruppe nur lesbar und nicht veränderbar zu gestalten. Diese Gruppen können anschließend das Dashboard nur noch ansehen, besitzen aber keine
Möglichkeit die Einstellungen oder Filter des Widgets zu verändern. Hierfür muss die jeweilige Gruppe in die folgende SysConfig-Option eingetragen werden:

`Znuny4OTRSDashboardWidgetSearchProfile::SearchProfile::Groups::Readonly`
