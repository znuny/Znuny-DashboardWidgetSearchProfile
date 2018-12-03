# Suchvorlagen Übersichts Widget

Im OTRS Standard gibt es keine Möglichkeit die Suchvorlagen der Tichetsuche des jeweiligen Agenten in der Übersicht als Widget zu verwenden. Diese Erweiterung beinhaltet die Funktionalität eines Übersichtswidget, in dem der jeweilige Agent zwischen seinen Suchervorlagen und der letzten ausgeführten Suche wählen kann.

![Suchvorlagen Widget](doc/de/images/widget.png)

Das Widget kann über die SysConfig "DashboardBackend###0001-SearchProfile" nach belieben angepasst werden, analog zu bestehenden Widgets. Für den Einsatz bedarf es keine weitere Konfiguration, das Widget kann nach der Installation der Erweiterung verwendet werden.

Jedem Agenten stehen seine persönlichen Suchvorlagen der Ticketsuche zur Verfügung.

## Gruppenbasierte Vorlagen

Je nach Suchprofil kann entschieden werden, ob das jeweilige Suchprofil nicht nur für den User selber, sondern auch für eine oder mehrere Gruppen zur Verfügung stehen soll.

![Suchvorlagen gruppenbasiert](doc/de/images/search_profile_grouped.png)

Wird das Suchprofil beispielsweise der Gruppe "users" zugeordnet, werden alle zugehörigen Benutzer mit dieser Gruppe dieses Suchprofil erhalten. Das Profil steht den Nutzern dann lesend zur Verfügung.
Eine Bearbeitung des Profils kann nur durch einen Admin durchgeführt werden.
