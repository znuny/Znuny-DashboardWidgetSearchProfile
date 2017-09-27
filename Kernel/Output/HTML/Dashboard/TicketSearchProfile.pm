# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# $origin: otrs - c7771de920c53a313eadda0a954c7bc7a8a48477 - Kernel/Output/HTML/Dashboard/TicketGeneric.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Znuny4OTRS::ObjectManagerDirectCall)

# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
# package Kernel::Output::HTML::Dashboard::TicketGeneric;
package Kernel::Output::HTML::Dashboard::TicketSearchProfile;

use base qw( Kernel::Output::HTML::Dashboard::TicketGeneric );
# ---

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub Run {
    my ( $Self, %Param ) = @_;

# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
#     my %SearchParams        = $Self->_SearchParamsGet(%Param);
#     my @Columns             = @{ $SearchParams{Columns} };
#     my %TicketSearch        = %{ $SearchParams{TicketSearch} };
#     my %TicketSearchSummary = %{ $SearchParams{TicketSearchSummary} };
#
#     my $CacheKey = join '-', $Self->{Name},
#         $Self->{Action},
#         $Self->{PageShown},
#         $Self->{StartHit},
#         $Self->{UserID};
#     my $CacheColumns = join(
#         ',',
#         map {
#             $_ . '=>' . $Self->{GetColumnFilterSelect}->{$_}
#             }
#             sort keys %{ $Self->{GetColumnFilterSelect} }
#     );
#     $CacheKey .= '-' . $CacheColumns if $CacheColumns;
#
#     $CacheKey .= '-' . $Self->{SortBy}  if defined $Self->{SortBy};
#     $CacheKey .= '-' . $Self->{OrderBy} if defined $Self->{OrderBy};
#
#     # CustomerInformationCenter shows data per CustomerID
#     if ( $Param{CustomerID} ) {
#         $CacheKey .= '-' . $Param{CustomerID};
#     }
#
    my $CacheKey = join '-', $Self->{Name},
        $Self->{Action},
        $Self->{PageShown},
        $Self->{StartHit},
        $Self->{UserID};
    my $CacheColumns = join(
        ',',
        map {
            $_ . '=>' . $Self->{GetColumnFilterSelect}->{$_}
            }
            sort keys %{ $Self->{GetColumnFilterSelect} }
    );
    $CacheKey .= '-' . $CacheColumns if $CacheColumns;

    $CacheKey .= '-' . $Self->{SortBy}  if defined $Self->{SortBy};
    $CacheKey .= '-' . $Self->{OrderBy} if defined $Self->{OrderBy};

    # CustomerInformationCenter shows data per CustomerID
    if ( $Param{CustomerID} ) {
        $CacheKey .= '-' . $Param{CustomerID};
    }

    # store the CacheKey in Self so we can use
    # it in the check for changed SearchProfiles
    $Self->{CacheKey} = $CacheKey;

    my %SearchParams        = $Self->_SearchParamsGet(%Param);
    my @Columns             = @{ $SearchParams{Columns} };
    my %TicketSearch        = %{ $SearchParams{TicketSearch} };
    my %TicketSearchSummary = %{ $SearchParams{TicketSearchSummary} };

# ---

    # get cache object
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # check cache
    my $TicketIDs = $CacheObject->Get(
        Type => 'Dashboard',
        Key  => $CacheKey . '-' . $Self->{Filter} . '-List',
    );

    # find and show ticket list
    my $CacheUsed = 1;

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    if ( !$TicketIDs ) {

        # quote all CustomerIDs
        if ( $TicketSearch{CustomerID} ) {
            $TicketSearch{CustomerID} = $Kernel::OM->Get('Kernel::System::DB')->QueryStringEscape(
                QueryString => $TicketSearch{CustomerID},
            );
        }

        # add sort by parameter to the search
        if (
            !defined $TicketSearch{SortBy}
            || !$Self->{ValidSortableColumns}->{ $TicketSearch{SortBy} }
            )
        {
            if ( $Self->{SortBy} && $Self->{ValidSortableColumns}->{ $Self->{SortBy} } ) {
                $TicketSearch{SortBy} = $Self->{SortBy};
            }
            else {
                $TicketSearch{SortBy} = 'Age';
            }
        }

        # add order by parameter to the search
        if ( $Self->{OrderBy} ) {
            $TicketSearch{OrderBy} = $Self->{OrderBy};
        }

        # add process management search terms
        if ( $Self->{Config}->{IsProcessWidget} ) {
            $TicketSearch{ 'DynamicField_' . $Self->{ProcessManagementProcessID} } = {
                Like => $Self->{ProcessList},
            };
        }

        $CacheUsed = 0;
        my @TicketIDsArray;
        if (
            !$Self->{Config}->{IsProcessWidget}
            || IsArrayRefWithData( $Self->{ProcessList} )
            )
        {
            @TicketIDsArray = $TicketObject->TicketSearch(
                Result => 'ARRAY',
# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
#                 %TicketSearch,
#                 %{ $TicketSearchSummary{ $Self->{Filter} } },
#                 %{ $Self->{ColumnFilter} },
#                 Limit => $Self->{PageShown} + $Self->{StartHit} - 1,
                %{ $Self->{ColumnFilter} },
                %TicketSearch,
                %{ $TicketSearchSummary{ $Self->{Filter} } },
                Limit => $Self->{PageShown} + $Self->{StartHit} - 1,

# ---
            );
        }
        $TicketIDs = \@TicketIDsArray;
    }

    # check cache
    my $Summary = $CacheObject->Get(
        Type => 'Dashboard',
        Key  => $CacheKey . '-Summary',
    );

    # if no cache or new list result, do count lookup
    if ( !$Summary || !$CacheUsed ) {
        TYPE:
        for my $Type ( sort keys %TicketSearchSummary ) {
            next TYPE if !$TicketSearchSummary{$Type};

            # copy original column filter
            my %ColumnFilter = %{ $Self->{ColumnFilter} || {} };

            # loop through all column filter elements
            for my $Element ( sort keys %ColumnFilter ) {

                # verify if current column filter element is already present in the ticket search
                # summary, to delete it from the column filter hash
                if ( $TicketSearchSummary{$Type}->{$Element} ) {
                    delete $ColumnFilter{$Element};
                }
            }

            # add process management search terms
            if ( $Self->{Config}->{IsProcessWidget} ) {
                $TicketSearch{ 'DynamicField_' . $Self->{ProcessManagementProcessID} } = {
                    Like => $Self->{ProcessList},
                };
            }

            $Summary->{$Type} = 0;

            if (
                !$Self->{Config}->{IsProcessWidget}
                || IsArrayRefWithData( $Self->{ProcessList} )
                )
            {
                $Summary->{$Type} = $TicketObject->TicketSearch(
                    Result => 'COUNT',
# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
#                     %TicketSearch,
#                     %{ $TicketSearchSummary{$Type} },
#                     %{ $Self->{ColumnFilter} },
#                     %ColumnFilter,
#
                    %{ $Self->{ColumnFilter} },
                    %ColumnFilter,
                    %TicketSearch,
                    %{ $TicketSearchSummary{$Type} },
# ---
                );
            }
        }
    }

    # set cache
    if ( !$CacheUsed && $Self->{Config}->{CacheTTLLocal} ) {
        $CacheObject->Set(
            Type  => 'Dashboard',
            Key   => $CacheKey . '-Summary',
            Value => $Summary,
            TTL   => $Self->{Config}->{CacheTTLLocal} * 60,
        );
        $CacheObject->Set(
            Type  => 'Dashboard',
            Key   => $CacheKey . '-' . $Self->{Filter} . '-List',
            Value => $TicketIDs,
            TTL   => $Self->{Config}->{CacheTTLLocal} * 60,
        );
    }

    # set css class
    $Summary->{ $Self->{Filter} . '::Selected' } = 'Selected';

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get filter ticket counts
    $LayoutObject->Block(
        Name => 'ContentLargeTicketGenericFilter',
        Data => {
            %Param,
            %{ $Self->{Config} },
            Name => $Self->{Name},
            %{$Summary},
        },
    );

# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
#
#     # get config object
#     my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
#
#     # show also watcher if feature is enabled and there is a watcher filter
#     if ( $ConfigObject->Get('Ticket::Watcher') && $TicketSearchSummary{Watcher} ) {
#         $LayoutObject->Block(
#             Name => 'ContentLargeTicketGenericFilterWatcher',
#             Data => {
#                 %Param,
#                 %{ $Self->{Config} },
#                 Name => $Self->{Name},
#                 %{$Summary},
#             },
#         );
#     }
#
#     # show also responsible if feature is enabled and there is a responsible filter
#     if ( $ConfigObject->Get('Ticket::Responsible') && $TicketSearchSummary{Responsible} ) {
#         $LayoutObject->Block(
#             Name => 'ContentLargeTicketGenericFilterResponsible',
#             Data => {
#                 %Param,
#                 %{ $Self->{Config} },
#                 Name => $Self->{Name},
#                 %{$Summary},
#             },
#         );
#     }
#
#     # show only my queues if we have the filter
#     if ( $TicketSearchSummary{MyQueues} ) {
#         $LayoutObject->Block(
#             Name => 'ContentLargeTicketGenericFilterMyQueues',
#             Data => {
#                 %Param,
#                 %{ $Self->{Config} },
#                 Name => $Self->{Name},
#                 %{$Summary},
#             },
#         );
#     }
#
#     # show only my services if we have the filter
#     if ( $TicketSearchSummary{MyServices} ) {
#         $LayoutObject->Block(
#             Name => 'ContentLargeTicketGenericFilterMyServices',
#             Data => {
#                 %Param,
#                 %{ $Self->{Config} },
#                 Name => $Self->{Name},
#                 %{$Summary},
#             },
#         );
#     }
#
#     # show only locked if we have the filter
#     if ( $TicketSearchSummary{Locked} ) {
#         $LayoutObject->Block(
#             Name => 'ContentLargeTicketGenericFilterLocked',
#             Data => {
#                 %Param,
#                 %{ $Self->{Config} },
#                 Name => $Self->{Name},
#                 %{$Summary},
#             },
#         );
#     }

    # order search profiles and make sure
    # last-search is at the last position
    my %SearchProfiles = %{ $Summary };
    delete $SearchProfiles{'last-search'};
    my @SearchProfiles = sort keys %SearchProfiles;
    push @SearchProfiles, 'last-search';

    # display the search profiles in a list
    PROFILE:
    for my $SearchProfile ( @SearchProfiles ) {

        next PROFILE if $SearchProfile =~ m{::Selected\z}xms;

        $LayoutObject->Block(
            Name => 'ContentLargeTicketGenericSearchProfile',
            Data => {
                %Param,
                %{ $Self->{Config} },
                Name     => $Self->{Name},
                Selected => $Summary->{$SearchProfile .'::Selected'},
                Profile  => $SearchProfile,
                Count    => $Summary->{ $SearchProfile },
            },
        );
    }
# ---

    # add page nav bar
    my $Total = $Summary->{ $Self->{Filter} } || 0;

    my %GetColumnFilter = $Self->{GetColumnFilter} ? %{ $Self->{GetColumnFilter} } : ();

    my $ColumnFilterLink = '';
    COLUMNNAME:
    for my $ColumnName ( sort keys %GetColumnFilter ) {
        next COLUMNNAME if !$ColumnName;
        next COLUMNNAME if !$GetColumnFilter{$ColumnName};
        $ColumnFilterLink
            .= ';' . $LayoutObject->Ascii2Html( Text => 'ColumnFilter' . $ColumnName )
            . '=' . $LayoutObject->Ascii2Html( Text => $GetColumnFilter{$ColumnName} )
    }

    my $LinkPage =
        'Subaction=Element;Name=' . $Self->{Name}
        . ';Filter=' . $Self->{Filter}
        . ';SortBy=' .  ( $Self->{SortBy}  || '' )
        . ';OrderBy=' . ( $Self->{OrderBy} || '' )
        . $ColumnFilterLink
        . ';';

    if ( $Param{CustomerID} ) {
        $LinkPage .= "CustomerID=$Param{CustomerID};";
    }
    my %PageNav = $LayoutObject->PageNavBar(
        StartHit       => $Self->{StartHit},
        PageShown      => $Self->{PageShown},
        AllHits        => $Total || 1,
        Action         => 'Action=' . $LayoutObject->{Action},
        Link           => $LinkPage,
        AJAXReplace    => 'Dashboard' . $Self->{Name},
        IDPrefix       => 'Dashboard' . $Self->{Name},
        KeepScriptTags => $Param{AJAX},
    );
    $LayoutObject->Block(
        Name => 'ContentLargeTicketGenericFilterNavBar',
        Data => {
            %{ $Self->{Config} },
            Name => $Self->{Name},
            %PageNav,
        },
    );

    # show table header
    $LayoutObject->Block(
        Name => 'ContentLargeTicketGenericHeader',
        Data => {},
    );

    # define which meta items will be shown
    my @MetaItems = $LayoutObject->TicketMetaItemsCount();

    # show non-labeled table headers
    my $CSS = '';
    my $OrderBy;
    for my $Item (@MetaItems) {
        $CSS = '';
        my $Title = $Item;
        if ( $Self->{SortBy} && ( $Self->{SortBy} eq $Item ) ) {
            if ( $Self->{OrderBy} && ( $Self->{OrderBy} eq 'Up' ) ) {
                $OrderBy = 'Down';
                $CSS .= ' SortAscendingLarge';
            }
            else {
                $OrderBy = 'Up';
                $CSS .= ' SortDescendingLarge';
            }

            # set title description
            my $TitleDesc = $OrderBy eq 'Down' ? Translatable('sorted ascending') : Translatable('sorted descending');
            $TitleDesc = $LayoutObject->{LanguageObject}->Translate($TitleDesc);
            $Title .= ', ' . $TitleDesc;
        }

        # add surrounding container
        $LayoutObject->Block(
            Name => 'GeneralOverviewHeader',
        );
        $LayoutObject->Block(
            Name => 'ContentLargeTicketGenericHeaderMeta',
            Data => {
                CSS => $CSS,
            },
        );

        if ( $Item eq 'New Article' ) {

            $LayoutObject->Block(
                Name => 'ContentLargeTicketGenericHeaderMetaEmpty',
                Data => {
                    HeaderColumnName => $Item,
                },
            );
        }
        else {
            $LayoutObject->Block(
                Name => 'ContentLargeTicketGenericHeaderMetaLink',
                Data => {
                    %Param,
                    Name             => $Self->{Name},
                    OrderBy          => $OrderBy || 'Up',
                    HeaderColumnName => $Item,
                    Title            => $Title,
                },
            );
        }
    }

    # show all needed headers
    HEADERCOLUMN:
    for my $HeaderColumn (@Columns) {

        # skip CustomerID if Customer Information Center
        if (
            $Self->{Action} eq 'AgentCustomerInformationCenter'
            && $HeaderColumn eq 'CustomerID'
            )
        {
            next HEADERCOLUMN;
        }

        if ( $HeaderColumn !~ m{\A DynamicField_}xms ) {

            $CSS = '';
            my $Title = $LayoutObject->{LanguageObject}->Translate($HeaderColumn);

            if ( $Self->{SortBy} && ( $Self->{SortBy} eq $HeaderColumn ) ) {
                if ( $Self->{OrderBy} && ( $Self->{OrderBy} eq 'Up' ) ) {
                    $OrderBy = 'Down';
                    $CSS .= ' SortAscendingLarge';
                }
                else {
                    $OrderBy = 'Up';
                    $CSS .= ' SortDescendingLarge';
                }

                # add title description
                my $TitleDesc
                    = $OrderBy eq 'Down' ? Translatable('sorted ascending') : Translatable('sorted descending');
                $TitleDesc = $LayoutObject->{LanguageObject}->Translate($TitleDesc);
                $Title .= ', ' . $TitleDesc;
            }

            # translate the column name to write it in the current language
            my $TranslatedWord;
            if ( $HeaderColumn eq 'EscalationTime' ) {
                $TranslatedWord = $LayoutObject->{LanguageObject}->Translate('Service Time');
            }
            elsif ( $HeaderColumn eq 'EscalationResponseTime' ) {
                $TranslatedWord = $LayoutObject->{LanguageObject}->Translate('First Response Time');
            }
            elsif ( $HeaderColumn eq 'EscalationSolutionTime' ) {
                $TranslatedWord = $LayoutObject->{LanguageObject}->Translate('Solution Time');
            }
            elsif ( $HeaderColumn eq 'EscalationUpdateTime' ) {
                $TranslatedWord = $LayoutObject->{LanguageObject}->Translate('Update Time');
            }
            elsif ( $HeaderColumn eq 'PendingTime' ) {
                $TranslatedWord = $LayoutObject->{LanguageObject}->Translate('Pending till');
            }
            else {
                $TranslatedWord = $LayoutObject->{LanguageObject}->Translate($HeaderColumn);
            }

            # add surrounding container
            $LayoutObject->Block(
                Name => 'GeneralOverviewHeader',
            );
            $LayoutObject->Block(
                Name => 'ContentLargeTicketGenericHeaderTicketHeader',
                Data => {},
            );

            if ( $HeaderColumn eq 'TicketNumber' ) {
                $LayoutObject->Block(
                    Name => 'ContentLargeTicketGenericHeaderTicketNumberColumn',
                    Data => {
                        %Param,
                        CSS => $CSS || '',
                        Name    => $Self->{Name},
                        OrderBy => $OrderBy || 'Up',
                        Filter  => $Self->{Filter},
                        Title   => $Title,
                    },
                );
                next HEADERCOLUMN;
            }

            my $FilterTitle     = $TranslatedWord;
            my $FilterTitleDesc = Translatable('filter not active');
            if ( $Self->{GetColumnFilterSelect} && $Self->{GetColumnFilterSelect}->{$HeaderColumn} )
            {
                $CSS .= ' FilterActive';
                $FilterTitleDesc = Translatable('filter active');
            }
            $FilterTitleDesc = $LayoutObject->{LanguageObject}->Translate($FilterTitleDesc);
            $FilterTitle .= ', ' . $FilterTitleDesc;

            $LayoutObject->Block(
                Name => 'ContentLargeTicketGenericHeaderColumn',
                Data => {
                    HeaderColumnName     => $HeaderColumn   || '',
                    HeaderNameTranslated => $TranslatedWord || $HeaderColumn,
                    CSS                  => $CSS            || '',
                },
            );

            # verify if column is filterable and sortable
            if (
                $Self->{ValidSortableColumns}->{$HeaderColumn}
                && $Self->{ValidFilterableColumns}->{$HeaderColumn}
                )
            {

                my $Css;
                if (
                    $HeaderColumn eq 'CustomerID'
                    || $HeaderColumn eq 'Responsible'
                    || $HeaderColumn eq 'Owner'
                    )
                {
                    $Css = 'Hidden';
                }

                # variable to save the filter's HTML code
                my $ColumnFilterHTML = $Self->_InitialColumnFilter(
                    ColumnName => $HeaderColumn,
                    Css        => $Css,
                );

                $LayoutObject->Block(
                    Name => 'ContentLargeTicketGenericHeaderColumnFilterLink',
                    Data => {
                        %Param,
                        HeaderColumnName     => $HeaderColumn,
                        CSS                  => $CSS,
                        HeaderNameTranslated => $TranslatedWord || $HeaderColumn,
                        ColumnFilterStrg     => $ColumnFilterHTML,
                        OrderBy              => $OrderBy || 'Up',
                        SortBy               => $Self->{SortBy} || 'Age',
                        Name                 => $Self->{Name},
                        Title                => $Title,
                        FilterTitle          => $FilterTitle,
                    },
                );

                if ( $HeaderColumn eq 'CustomerID' ) {

                    $LayoutObject->Block(
                        Name => 'ContentLargeTicketGenericHeaderColumnFilterLinkCustomerIDSearch',
                        Data => {
                            minQueryLength      => 2,
                            queryDelay          => 100,
                            maxResultsDisplayed => 20,
                        },
                    );
                }
                elsif ( $HeaderColumn eq 'Responsible' || $HeaderColumn eq 'Owner' ) {

                    $LayoutObject->Block(
                        Name => 'ContentLargeTicketGenericHeaderColumnFilterLinkUserSearch',
                        Data => {
                            minQueryLength      => 2,
                            queryDelay          => 100,
                            maxResultsDisplayed => 20,
                        },
                    );
                }
            }

            # verify if column is just filterable
            elsif ( $Self->{ValidFilterableColumns}->{$HeaderColumn} ) {

                my $Css;
                if ( $HeaderColumn eq 'CustomerUserID' ) {
                    $Css = 'Hidden';
                }

                # variable to save the filter's HTML code
                my $ColumnFilterHTML = $Self->_InitialColumnFilter(
                    ColumnName => $HeaderColumn,
                    Css        => $Css,
                );

                $LayoutObject->Block(
                    Name => 'ContentLargeTicketGenericHeaderColumnFilter',
                    Data => {
                        %Param,
                        HeaderColumnName     => $HeaderColumn,
                        CSS                  => $CSS,
                        HeaderNameTranslated => $TranslatedWord || $HeaderColumn,
                        ColumnFilterStrg     => $ColumnFilterHTML,
                        Name                 => $Self->{Name},
                        Title                => $Title,
                        FilterTitle          => $FilterTitle,
                    },
                );

                if ( $HeaderColumn eq 'CustomerUserID' ) {

                    $LayoutObject->Block(
                        Name => 'ContentLargeTicketGenericHeaderColumnFilterLinkCustomerUserSearch',
                        Data => {
                            minQueryLength      => 2,
                            queryDelay          => 100,
                            maxResultsDisplayed => 20,
                        },
                    );
                }
            }

            # verify if column is just sortable
            elsif ( $Self->{ValidSortableColumns}->{$HeaderColumn} ) {
                $LayoutObject->Block(
                    Name => 'ContentLargeTicketGenericHeaderColumnLink',
                    Data => {
                        %Param,
                        HeaderColumnName     => $HeaderColumn,
                        CSS                  => $CSS,
                        HeaderNameTranslated => $TranslatedWord || $HeaderColumn,
                        OrderBy              => $OrderBy || 'Up',
                        SortBy               => $Self->{SortBy} || $HeaderColumn,
                        Name                 => $Self->{Name},
                        Title                => $Title,
                    },
                );
            }
            else {
                $LayoutObject->Block(
                    Name => 'ContentLargeTicketGenericHeaderColumnEmpty',
                    Data => {
                        %Param,
                        HeaderNameTranslated => $TranslatedWord || $HeaderColumn,
                        HeaderColumnName     => $HeaderColumn,
                        CSS                  => $CSS,
                        Title                => $Title,
                    },
                );
            }
        }

        # Dynamic fields
        else {
            my $DynamicFieldConfig;
            my $DFColumn = $HeaderColumn;
            $DFColumn =~ s/DynamicField_//g;
            DYNAMICFIELD:
            for my $DFConfig ( @{ $Self->{DynamicField} } ) {
                next DYNAMICFIELD if !IsHashRefWithData($DFConfig);
                next DYNAMICFIELD if $DFConfig->{Name} ne $DFColumn;

                $DynamicFieldConfig = $DFConfig;
                last DYNAMICFIELD;
            }
            next HEADERCOLUMN if !IsHashRefWithData($DynamicFieldConfig);

            my $Label = $DynamicFieldConfig->{Label};

            my $TranslatedLabel = $LayoutObject->{LanguageObject}->Translate($Label);

            my $DynamicFieldName = 'DynamicField_' . $DynamicFieldConfig->{Name};

            my $CSS             = '';
            my $FilterTitle     = $Label;
            my $FilterTitleDesc = Translatable('filter not active');
            if (
                $Self->{GetColumnFilterSelect}
                && defined $Self->{GetColumnFilterSelect}->{$DynamicFieldName}
                )
            {
                $CSS .= 'FilterActive ';
                $FilterTitleDesc = Translatable('filter active');
            }
            $FilterTitleDesc = $LayoutObject->{LanguageObject}->Translate($FilterTitleDesc);
            $FilterTitle .= ', ' . $FilterTitleDesc;

            # get field sortable condition
            my $IsSortable = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsSortable',
            );

            # set title
            my $Title = $Label;

            # add surrounding container
            $LayoutObject->Block(
                Name => 'GeneralOverviewHeader',
            );
            $LayoutObject->Block(
                Name => 'ContentLargeTicketGenericHeaderTicketHeader',
                Data => {},
            );

            if ($IsSortable) {
                my $OrderBy;
                if (
                    $Self->{SortBy}
                    && ( $Self->{SortBy} eq ( 'DynamicField_' . $DynamicFieldConfig->{Name} ) )
                    )
                {
                    if ( $Self->{OrderBy} && ( $Self->{OrderBy} eq 'Up' ) ) {
                        $OrderBy = 'Down';
                        $CSS .= ' SortAscendingLarge';
                    }
                    else {
                        $OrderBy = 'Up';
                        $CSS .= ' SortDescendingLarge';
                    }

                    # add title description
                    my $TitleDesc
                        = $OrderBy eq 'Down' ? Translatable('sorted ascending') : Translatable('sorted descending');
                    $TitleDesc = $LayoutObject->{LanguageObject}->Translate($TitleDesc);
                    $Title .= ', ' . $TitleDesc;
                }

                $LayoutObject->Block(
                    Name => 'ContentLargeTicketGenericHeaderColumn',
                    Data => {
                        HeaderColumnName => $DynamicFieldName || '',
                        CSS => $CSS || '',
                    },
                );

                # check if the dynamic field is sortable and filterable (sortable check was made before)
                if ( $Self->{ValidFilterableColumns}->{$DynamicFieldName} ) {

                    # variable to save the filter's HTML code
                    my $ColumnFilterHTML = $Self->_InitialColumnFilter(
                        ColumnName => $DynamicFieldName,
                        Label      => $Label,
                    );

                    # output sortable and filterable dynamic field
                    $LayoutObject->Block(
                        Name => 'ContentLargeTicketGenericHeaderColumnFilterLink',
                        Data => {
                            %Param,
                            HeaderColumnName     => $DynamicFieldName,
                            CSS                  => $CSS,
                            HeaderNameTranslated => $TranslatedLabel || $DynamicFieldName,
                            ColumnFilterStrg     => $ColumnFilterHTML,
                            OrderBy              => $OrderBy || 'Up',
                            SortBy               => $Self->{SortBy} || 'Age',
                            Name                 => $Self->{Name},
                            Title                => $Title,
                            FilterTitle          => $FilterTitle,
                        },
                    );
                }

                # otherwise the dynamic field is only sortable (sortable check was made before)
                else {

                    # output sortable dynamic field
                    $LayoutObject->Block(
                        Name => 'ContentLargeTicketGenericHeaderColumnLink',
                        Data => {
                            %Param,
                            HeaderColumnName     => $DynamicFieldName,
                            CSS                  => $CSS,
                            HeaderNameTranslated => $TranslatedLabel || $DynamicFieldName,
                            OrderBy              => $OrderBy || 'Up',
                            SortBy               => $Self->{SortBy} || $DynamicFieldName,
                            Name                 => $Self->{Name},
                            Title                => $Title,
                            FilterTitle          => $FilterTitle,
                        },
                    );
                }
            }

            # if the dynamic field was not sortable (check was made and fail before)
            # it might be filterable
            elsif ( $Self->{ValidFilterableColumns}->{$DynamicFieldName} ) {

                $LayoutObject->Block(
                    Name => 'ContentLargeTicketGenericHeaderColumn',
                    Data => {
                        HeaderColumnName => $DynamicFieldName || '',
                        CSS              => $CSS              || '',
                        Title            => $Title,
                    },
                );

                # variable to save the filter's HTML code
                my $ColumnFilterHTML = $Self->_InitialColumnFilter(
                    ColumnName => $DynamicFieldName,
                    Label      => $Label,
                );

                # output filterable (not sortable) dynamic field
                $LayoutObject->Block(
                    Name => 'ContentLargeTicketGenericHeaderColumnFilter',
                    Data => {
                        %Param,
                        HeaderColumnName     => $DynamicFieldName,
                        CSS                  => $CSS,
                        HeaderNameTranslated => $TranslatedLabel || $DynamicFieldName,
                        ColumnFilterStrg     => $ColumnFilterHTML,
                        Name                 => $Self->{Name},
                        Title                => $Title,
                        FilterTitle          => $FilterTitle,
                    },
                );
            }

            # otherwise the field is not filterable and not sortable
            else {

                $LayoutObject->Block(
                    Name => 'ContentLargeTicketGenericHeaderColumn',
                    Data => {
                        HeaderColumnName => $DynamicFieldName || '',
                        CSS => $CSS || '',
                    },
                );

                # output plain dynamic field header (not filterable, not sortable)
                $LayoutObject->Block(
                    Name => 'ContentLargeTicketGenericHeaderColumnEmpty',
                    Data => {
                        %Param,
                        HeaderNameTranslated => $TranslatedLabel || $DynamicFieldName,
                        HeaderColumnName     => $DynamicFieldName,
                        CSS                  => $CSS,
                        Title                => $Title,
                    },
                );
            }
        }
    }

    # show tickets
    my $Count = 0;
    TICKETID:
    for my $TicketID ( @{$TicketIDs} ) {
        $Count++;
        next TICKETID if $Count < $Self->{StartHit};
        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            UserID        => $Self->{UserID},
            DynamicFields => 0,
            Silent        => 1
        );

        next TICKETID if !%Ticket;

        # set a default title if ticket has no title
        if ( !$Ticket{Title} ) {
            $Ticket{Title} = $LayoutObject->{LanguageObject}->Translate(
                'This ticket has no title or subject'
            );
        }

        my $WholeTitle = $Ticket{Title} || '';
        $Ticket{Title} = $TicketObject->TicketSubjectClean(
            TicketNumber => $Ticket{TicketNumber},
            Subject      => $Ticket{Title},
        );

        # create human age
        if ( $Self->{Config}->{Time} ne 'Age' ) {
            $Ticket{Time} = $LayoutObject->CustomerAgeInHours(
                Age   => $Ticket{ $Self->{Config}->{Time} },
                Space => ' ',
            );
        }
        else {
            $Ticket{Time} = $LayoutObject->CustomerAge(
                Age   => $Ticket{ $Self->{Config}->{Time} },
                Space => ' ',
            );
        }

        # show ticket
        $LayoutObject->Block(
            Name => 'ContentLargeTicketGenericRow',
            Data => \%Ticket,
        );

        # show ticket flags
        my @TicketMetaItems = $LayoutObject->TicketMetaItems(
            Ticket => \%Ticket,
        );
        for my $Item (@TicketMetaItems) {

            $LayoutObject->Block(
                Name => 'GeneralOverviewRow',
            );
            $LayoutObject->Block(
                Name => 'ContentLargeTicketGenericRowMeta',
                Data => {},
            );
            if ($Item) {
                $LayoutObject->Block(
                    Name => 'ContentLargeTicketGenericRowMetaImage',
                    Data => $Item,
                );
            }
        }

        # save column content
        my $DataValue;

        # get needed objects
        my $BackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
        my $UserObject    = $Kernel::OM->Get('Kernel::System::User');

        # show all needed columns
        COLUMN:
        for my $Column (@Columns) {

            # skip CustomerID if Customer Information Center
            if (
                $Self->{Action} eq 'AgentCustomerInformationCenter'
                && $Column eq 'CustomerID'
                )
            {
                next COLUMN;
            }

            if ( $Column !~ m{\A DynamicField_}xms ) {

                $LayoutObject->Block(
                    Name => 'GeneralOverviewRow',
                );
                $LayoutObject->Block(
                    Name => 'ContentLargeTicketGenericTicketColumn',
                    Data => {},
                );

                my $BlockType = '';
                my $CSSClass  = '';

                if ( $Column eq 'TicketNumber' ) {
                    $LayoutObject->Block(
                        Name => 'ContentLargeTicketGenericTicketNumber',
                        Data => {
                            %Ticket,
                            Title => $Ticket{Title},
                        },
                    );
                    next COLUMN;
                }
                elsif ( $Column eq 'EscalationTime' ) {
                    my %EscalationData;
                    $EscalationData{EscalationTime}            = $Ticket{EscalationTime};
                    $EscalationData{EscalationDestinationDate} = $Ticket{EscalationDestinationDate};

                    $EscalationData{EscalationTimeHuman} = $LayoutObject->CustomerAgeInHours(
                        Age   => $EscalationData{EscalationTime},
                        Space => ' ',
                    );
                    $EscalationData{EscalationTimeWorkingTime} = $LayoutObject->CustomerAgeInHours(
                        Age   => $EscalationData{EscalationTimeWorkingTime},
                        Space => ' ',
                    );
                    if ( defined $Ticket{EscalationTime} && $Ticket{EscalationTime} < 60 * 60 * 1 )
                    {
                        $EscalationData{EscalationClass} = 'Warning';
                    }
                    $LayoutObject->Block(
                        Name => 'ContentLargeTicketGenericEscalationTime',
                        Data => {%EscalationData},
                    );
                    next COLUMN;

                    $DataValue = $LayoutObject->CustomerAge(
                        Age   => $Ticket{'EscalationTime'},
                        Space => ' '
                    );
                }
                elsif ( $Column eq 'Age' ) {
                    $DataValue = $LayoutObject->CustomerAge(
                        Age   => $Ticket{Age},
                        Space => ' ',
                    );
                }
                elsif ( $Column eq 'EscalationSolutionTime' ) {
                    $BlockType = 'Escalation';
                    $DataValue = $LayoutObject->CustomerAgeInHours(
                        Age => $Ticket{SolutionTime} || 0,
                        Space => ' ',
                    );
                    if ( defined $Ticket{SolutionTime} && $Ticket{SolutionTime} < 60 * 60 * 1 ) {
                        $CSSClass = 'Warning';
                    }
                }
                elsif ( $Column eq 'EscalationResponseTime' ) {
                    $BlockType = 'Escalation';
                    $DataValue = $LayoutObject->CustomerAgeInHours(
                        Age => $Ticket{FirstResponseTime} || 0,
                        Space => ' ',
                    );
                    if (
                        defined $Ticket{FirstResponseTime}
                        && $Ticket{FirstResponseTime} < 60 * 60 * 1
                        )
                    {
                        $CSSClass = 'Warning';
                    }
                }
                elsif ( $Column eq 'EscalationUpdateTime' ) {
                    $BlockType = 'Escalation';
                    $DataValue = $LayoutObject->CustomerAgeInHours(
                        Age => $Ticket{UpdateTime} || 0,
                        Space => ' ',
                    );
                    if ( defined $Ticket{UpdateTime} && $Ticket{UpdateTime} < 60 * 60 * 1 ) {
                        $CSSClass = 'Warning';
                    }
                }
                elsif ( $Column eq 'PendingTime' ) {
                    $BlockType = 'Escalation';
                    $DataValue = $LayoutObject->CustomerAge(
                        Age   => $Ticket{'UntilTime'},
                        Space => ' '
                    );
                    if ( defined $Ticket{UntilTime} && $Ticket{UntilTime} < -1 ) {
                        $CSSClass = 'Warning';
                    }
                }
                elsif ( $Column eq 'Owner' ) {

                    # get owner info
                    my %OwnerInfo = $UserObject->GetUserData(
                        UserID => $Ticket{OwnerID},
                    );
                    $DataValue = $OwnerInfo{'UserFirstname'} . ' ' . $OwnerInfo{'UserLastname'};
                }
                elsif ( $Column eq 'Responsible' ) {

                    # get responsible info
                    my %ResponsibleInfo = $UserObject->GetUserData(
                        UserID => $Ticket{ResponsibleID},
                    );
                    $DataValue = $ResponsibleInfo{'UserFirstname'} . ' '
                        . $ResponsibleInfo{'UserLastname'};
                }
                elsif (
                    $Column eq 'State'
                    || $Column eq 'Lock'
                    || $Column eq 'Priority'
                    )
                {
                    $BlockType = 'Translatable';
                    $DataValue = $Ticket{$Column};
                }
                elsif ( $Column eq 'Created' || $Column eq 'Changed' ) {
                    $BlockType = 'Time';
                    $DataValue = $Ticket{$Column};
                }
                elsif ( $Column eq 'CustomerName' ) {

                    # get customer name
                    my $CustomerName;
                    if ( $Ticket{CustomerUserID} ) {
                        $CustomerName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                            UserLogin => $Ticket{CustomerUserID},
                        );
                    }
                    $DataValue = $CustomerName;
                }
                elsif ( $Column eq 'CustomerCompanyName' ) {
                    my %CustomerCompanyData;
                    if ( $Ticket{CustomerID} ) {
                        %CustomerCompanyData = $Kernel::OM->Get('Kernel::System::CustomerCompany')->CustomerCompanyGet(
                            CustomerID => $Ticket{CustomerID},
                        );
                    }
                    $DataValue = $CustomerCompanyData{CustomerCompanyName};
                }
                else {
                    $DataValue = $Ticket{$Column};
                }

                if ( $Column eq 'Title' ) {
                    $LayoutObject->Block(
                        Name => "ContentLargeTicketTitle",
                        Data => {
                            Title => "$DataValue " || '',
                            WholeTitle => $WholeTitle,
                            Class      => $CSSClass || '',
                        },
                    );

                }
                else {
                    $LayoutObject->Block(
                        Name => "ContentLargeTicketGenericColumn$BlockType",
                        Data => {
                            GenericValue => $DataValue || '',
                            Class        => $CSSClass  || '',
                        },
                    );
                }

            }

            # Dynamic fields
            else {
                my $DynamicFieldConfig;
                my $DFColumn = $Column;
                $DFColumn =~ s/DynamicField_//g;
                DYNAMICFIELD:
                for my $DFConfig ( @{ $Self->{DynamicField} } ) {
                    next DYNAMICFIELD if !IsHashRefWithData($DFConfig);
                    next DYNAMICFIELD if $DFConfig->{Name} ne $DFColumn;

                    $DynamicFieldConfig = $DFConfig;
                    last DYNAMICFIELD;
                }
                next COLUMN if !IsHashRefWithData($DynamicFieldConfig);

                # get field value
                my $Value = $BackendObject->ValueGet(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    ObjectID           => $TicketID,
                );

                my $ValueStrg = $BackendObject->DisplayValueRender(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    Value              => $Value,
                    ValueMaxChars      => 20,
                    LayoutObject       => $LayoutObject,
                );

                $LayoutObject->Block(
                    Name => 'ContentLargeTicketGenericDynamicField',
                    Data => {
                        Value => $ValueStrg->{Value},
                        Title => $ValueStrg->{Title},
                    },
                );

                if ( $ValueStrg->{Link} ) {
                    $LayoutObject->Block(
                        Name => 'ContentLargeTicketGenericDynamicFieldLink',
                        Data => {
                            Value                       => $ValueStrg->{Value},
                            Title                       => $ValueStrg->{Title},
                            Link                        => $ValueStrg->{Link},
                            $DynamicFieldConfig->{Name} => $ValueStrg->{Title},
                        },
                    );
                }
                else {
                    $LayoutObject->Block(
                        Name => 'ContentLargeTicketGenericDynamicFieldPlain',
                        Data => {
                            Value => $ValueStrg->{Value},
                            Title => $ValueStrg->{Title},
                        },
                    );
                }
            }

        }

    }

    # show "none" if no ticket is available
    if ( !$TicketIDs || !@{$TicketIDs} ) {
        $LayoutObject->Block(
            Name => 'ContentLargeTicketGenericNone',
            Data => {},
        );
    }

    # check for refresh time
    my $Refresh = '';
    if ( $Self->{UserRefreshTime} ) {
        $Refresh = 60 * $Self->{UserRefreshTime};
        my $NameHTML = $Self->{Name};
        $NameHTML =~ s{-}{_}xmsg;
        $LayoutObject->Block(
            Name => 'ContentLargeTicketGenericRefresh',
            Data => {
                %{ $Self->{Config} },
                Name        => $Self->{Name},
                NameHTML    => $NameHTML,
                RefreshTime => $Refresh,
                CustomerID  => $Param{CustomerID},
                %{$Summary},
            },
        );
    }

    # check for active filters and add a 'remove filters' button to the widget header
    if ( $Self->{GetColumnFilterSelect} && IsHashRefWithData( $Self->{GetColumnFilterSelect} ) ) {
        $LayoutObject->Block(
            Name => 'ContentLargeTicketGenericRemoveFilters',
            Data => {
                Name       => $Self->{Name},
                CustomerID => $Param{CustomerID},
            },
        );
    }
    else {
        $LayoutObject->Block(
            Name => 'ContentLargeTicketGenericRemoveFiltersRemove',
            Data => {
                Name => $Self->{Name},
            },
        );
    }

    my $Content = $LayoutObject->Output(
# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
#         TemplateFile => 'AgentDashboardTicketGeneric',
#
        TemplateFile => 'AgentDashboardTicketSearchProfile',
# ---
        Data         => {
            %{ $Self->{Config} },
            Name => $Self->{Name},
            %{$Summary},
            FilterValue => $Self->{Filter},
            CustomerID  => $Self->{CustomerID},
        },
        KeepScriptTags => $Param{AJAX},
    );

    return $Content;
}

sub _SearchParamsGet {
    my ( $Self, %Param ) = @_;

    # get all search base attributes
    my %TicketSearch;
    my %DynamicFieldsParameters;
    my @Params = split /;/, $Self->{Config}->{Attributes};

    # read user preferences and config to get columns that
    # should be shown in the dashboard widget (the preferences
    # have precedence)
    my %Preferences = $Kernel::OM->Get('Kernel::System::User')->GetPreferences(
        UserID => $Self->{UserID},
    );

    # get column names from Preferences
    my $PreferencesColumn = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
        Data => $Preferences{ $Self->{PrefKeyColumns} },
    );

    # check for default settings
    my @Columns;
    if (
        $Self->{Config}->{DefaultColumns}
        && IsHashRefWithData( $Self->{Config}->{DefaultColumns} )
        )
    {
        @Columns = grep { $Self->{Config}->{DefaultColumns}->{$_} eq '2' }
# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
#             sort { $Self->_DefaultColumnSort() } keys %{ $Self->{Config}->{DefaultColumns} };
            sort { $Self->_DefaultColumnSortTicketSearchProfile() } keys %{ $Self->{Config}->{DefaultColumns} };
# ---
    }
    if ($PreferencesColumn) {
        if ( $PreferencesColumn->{Columns} && %{ $PreferencesColumn->{Columns} } ) {
            @Columns = grep {
                defined $PreferencesColumn->{Columns}->{$_}
                    && $PreferencesColumn->{Columns}->{$_} eq '1'
# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
#             } sort { $Self->_DefaultColumnSort() } keys %{ $Self->{Config}->{DefaultColumns} };
            } sort { $Self->_DefaultColumnSortTicketSearchProfile() } keys %{ $Self->{Config}->{DefaultColumns} };
# ---
        }
        if ( $PreferencesColumn->{Order} && @{ $PreferencesColumn->{Order} } ) {
            @Columns = @{ $PreferencesColumn->{Order} };
        }

        # remove duplicate columns
        my %UniqueColumns;
        my @ColumnsEnabledAux;

        for my $Column (@Columns) {
            if ( !$UniqueColumns{$Column} ) {
                push @ColumnsEnabledAux, $Column;
            }
            $UniqueColumns{$Column} = 1;
        }

        # set filtered column list
        @Columns = @ColumnsEnabledAux;
    }

    # always set TicketNumber
    if ( !grep { $_ eq 'TicketNumber' } @Columns ) {
        unshift @Columns, 'TicketNumber';
    }

# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
#     # also always set ProcessID and ActivityID (for process widgets)
#     if ( $Self->{Config}->{IsProcessWidget} ) {
#
#         my @AlwaysColumns = (
#             'DynamicField_' . $Self->{ProcessManagementProcessID},
#             'DynamicField_' . $Self->{ProcessManagementActivityID},
#         );
#         my $Resort;
#         for my $AlwaysColumn (@AlwaysColumns) {
#             if ( !grep { $_ eq $AlwaysColumn } @Columns ) {
#                 push @Columns, $AlwaysColumn;
#                 $Resort = 1;
#             }
#         }
#         if ($Resort) {
#             @Columns = sort { $Self->_DefaultColumnSort() } @Columns;
#         }
#     }
# ---
    {

        # loop through all the dynamic fields to get the ones that should be shown
        DYNAMICFIELDNAME:
        for my $DynamicFieldName (@Columns) {

            next DYNAMICFIELDNAME if $DynamicFieldName !~ m{ DynamicField_ }xms;

            # remove dynamic field prefix
            my $FieldName = $DynamicFieldName;
            $FieldName =~ s/DynamicField_//gi;
            $Self->{DynamicFieldFilter}->{$FieldName} = 1;
        }
    }

    # get the dynamic fields for this screen
    $Self->{DynamicField} = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => ['Ticket'],
        FieldFilter => $Self->{DynamicFieldFilter} || {},
    );

    # get dynamic field backend object
    my $BackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # get filterable Dynamic fields
    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $IsFiltrable = $BackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsFiltrable',
        );

        # if the dynamic field is filterable add it to the ValidFilterableColumns hash
        if ($IsFiltrable) {
            $Self->{ValidFilterableColumns}->{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = 1;
        }
    }

    # get sortable Dynamic fields
    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $IsSortable = $BackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsSortable',
        );

        # if the dynamic field is sortable add it to the ValidSortableColumns hash
        if ($IsSortable) {
            $Self->{ValidSortableColumns}->{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = 1;
        }
    }

# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
#     # get queue object
#     my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
#
#     STRING:
#     for my $String (@Params) {
#         next STRING if !$String;
#         my ( $Key, $Value ) = split /=/, $String;
#
#         if ( $Key eq 'CustomerID' ) {
#             $Key = "CustomerIDRaw";
#         }
#
#         # push ARRAYREF attributes directly in an ARRAYREF
#         if (
#             $Key
#             =~ /^(StateType|StateTypeIDs|Queues|QueueIDs|Types|TypeIDs|States|StateIDs|Priorities|PriorityIDs|Services|ServiceIDs|SLAs|SLAIDs|Locks|LockIDs|OwnerIDs|ResponsibleIDs|WatchUserIDs|ArchiveFlags|CreatedUserIDs|CreatedTypes|CreatedTypeIDs|CreatedPriorities|CreatedPriorityIDs|CreatedStates|CreatedStateIDs|CreatedQueues|CreatedQueueIDs)$/
#             )
#         {
#             if ( $Value =~ m{,}smx ) {
#                 push @{ $TicketSearch{$Key} }, split( /,/, $Value );
#             }
#             else {
#                 push @{ $TicketSearch{$Key} }, $Value;
#             }
#         }
#
#         # check if parameter is a dynamic field and capture dynamic field name (with DynamicField_)
#         # in $1 and the Operator in $2
#         # possible Dynamic Fields options include:
#         #   DynamicField_NameX_Equals=123;
#         #   DynamicField_NameX_Like=value*;
#         #   DynamicField_NameX_GreaterThan=2001-01-01 01:01:01;
#         #   DynamicField_NameX_GreaterThanEquals=2001-01-01 01:01:01;
#         #   DynamicField_NameX_SmallerThan=2002-02-02 02:02:02;
#         #   DynamicField_NameX_SmallerThanEquals=2002-02-02 02:02:02;
#         elsif ( $Key =~ m{\A (DynamicField_.+?) _ (.+?) \z}sxm ) {
#
#             # prevent adding ProcessManagement search parameters (for ProcessWidget)
#             if ( $Self->{Config}->{IsProcessWidget} ) {
#                 next STRING if $2 eq $Self->{ProcessManagementProcessID};
#                 next STRING if $2 eq $Self->{ProcessManagementActivityID};
#             }
#
#             push @{ $DynamicFieldsParameters{$1}->{$2} }, $Value;
#         }
#
#         elsif ( !defined $TicketSearch{$Key} ) {
#
#             # change sort by, if needed
#             if (
#                 $Key eq 'SortBy'
#                 && $Self->{SortBy}
#                 && $Self->{ValidSortableColumns}->{ $Self->{SortBy} }
#                 )
#             {
#                 $Value = $Self->{SortBy};
#             }
#             elsif ( $Key eq 'SortBy' && !$Self->{ValidSortableColumns}->{$Value} ) {
#                 $Value = 'Age';
#             }
#             $TicketSearch{$Key} = $Value;
#         }
#         elsif ( !ref $TicketSearch{$Key} ) {
#             my $ValueTmp = $TicketSearch{$Key};
#             $TicketSearch{$Key} = [$ValueTmp];
#             push @{ $TicketSearch{$Key} }, $Value;
#         }
#         else {
#             push @{ $TicketSearch{$Key} }, $Value;
#         }
#     }
#     %TicketSearch = (
#         %TicketSearch,
#         %DynamicFieldsParameters,
#         Permission => $Self->{Config}->{Permission} || 'ro',
#         UserID => $Self->{UserID},
#     );
#
#     # CustomerInformationCenter shows data per CustomerID
#     if ( $Param{CustomerID} ) {
#         $TicketSearch{CustomerIDRaw} = $Param{CustomerID};
#     }
#
#     # define filter attributes
#     my @MyQueues = $QueueObject->GetAllCustomQueues(
#         UserID => $Self->{UserID},
#     );
#     if ( !@MyQueues ) {
#         @MyQueues = (999_999);
#     }
#
#     # get all queues the agent is allowed to see (for my services)
#     my %ViewableQueues = $QueueObject->GetAllQueues(
#         UserID => $Self->{UserID},
#         Type   => 'ro',
#     );
#     my @ViewableQueueIDs = sort keys %ViewableQueues;
#     if ( !@ViewableQueueIDs ) {
#         @ViewableQueueIDs = (999_999);
#     }
#
#     # get the custom services from agent preferences
#     # set the service ids to an array of non existing service ids (0)
#     my @MyServiceIDs = (0);
#     if ( $Self->{UseTicketService} ) {
#         @MyServiceIDs = $Kernel::OM->Get('Kernel::System::Service')->GetAllCustomServices(
#             UserID => $Self->{UserID},
#         );
#
#         if ( !defined $MyServiceIDs[0] ) {
#             @MyServiceIDs = (0);
#         }
#     }
#
#     my %TicketSearchSummary = (
#         Locked => {
#             OwnerIDs => $TicketSearch{OwnerIDs} // [ $Self->{UserID}, ],
#             LockIDs => [ '2', '3' ],    # 'lock' and 'tmp_lock'
#         },
#         Watcher => {
#             WatchUserIDs => [ $Self->{UserID}, ],
#             LockIDs      => $TicketSearch{LockIDs} // undef,
#         },
#         Responsible => {
#             ResponsibleIDs => $TicketSearch{ResponsibleIDs} // [ $Self->{UserID}, ],
#             LockIDs        => $TicketSearch{LockIDs}        // undef,
#         },
#         MyQueues => {
#             QueueIDs => \@MyQueues,
#             LockIDs  => $TicketSearch{LockIDs} // undef,
#         },
#         MyServices => {
#             QueueIDs   => \@ViewableQueueIDs,
#             ServiceIDs => \@MyServiceIDs,
#             LockIDs    => $TicketSearch{LockIDs} // undef,
#         },
#         All => {
#             OwnerIDs => $TicketSearch{OwnerIDs} // undef,
#             LockIDs  => $TicketSearch{LockIDs}  // undef,
#         },
#     );
#
#     if ( defined $TicketSearch{LockIDs} || defined $TicketSearch{Locks} ) {
#         delete $TicketSearchSummary{Locked};
#     }
#
#     if ( defined $TicketSearch{WatchUserIDs} ) {
#         delete $TicketSearchSummary{Watcher};
#     }
#
#     if ( defined $TicketSearch{ResponsibleIDs} ) {
#         delete $TicketSearchSummary{Responsible};
#     }
#
#     if ( defined $TicketSearch{QueueIDs} || defined $TicketSearch{Queues} ) {
#         delete $TicketSearchSummary{MyQueues};
#         delete $TicketSearchSummary{MyServices}->{QueueIDs};
#     }
#
#     if ( !$Self->{UseTicketService} ) {
#         delete $TicketSearchSummary{MyServices};
#     }

    my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
    my $SearchProfileObject = $Kernel::OM->Get('Kernel::System::SearchProfile');
    my $UserObject          = $Kernel::OM->Get('Kernel::System::User');
    my $CacheObject         = $Kernel::OM->Get('Kernel::System::Cache');

    # taken from AgentTicketSearch
    my $Config = $ConfigObject->Get('Ticket::Frontend::AgentTicketSearch');

    %TicketSearch = (
        Permission          => $Self->{Config}->{Permission} || 'ro',
        UserID              => $Self->{UserID},
        ConditionInline     => $Config->{ExtendedSearchCondition},
        ContentSearchPrefix => '*',
        ContentSearchSuffix => '*',
        FullTextIndex       => 1,
    );

    my $UserLogin = $UserObject->UserLookup(
        UserID => $Self->{UserID},
    );

    my %SearchProfile = $SearchProfileObject->SearchProfileGet(
        Base      => 'TicketSearch',
        Name      => $Self->{Filter},
        UserLogin => $UserLogin,
    );

    my %SearchProfiles = $SearchProfileObject->SearchProfileList(
        Base      => 'TicketSearch',
        UserLogin => $UserLogin,
    );

    # check cache
    my $Summary = $CacheObject->Get(
        Type => 'Dashboard',
        Key  => $Self->{CacheKey} . '-Summary',
    );

    # check if we have to clean up the cache
    # in cases the search profiles have changed
    if ( IsHashRefWithData($Summary) ) {

        my @CachedSearchProfiles  = grep { $_ !~ m{::Selected\z}xms } sort keys %{ $Summary };
        my @CurrentSearchProfiles = sort keys %SearchProfiles;

        my $CacheDiffers = DataIsDifferent(
            Data1 => \@CachedSearchProfiles,
            Data2 => \@CurrentSearchProfiles,
        );

        if ( $CacheDiffers ) {

            $CacheObject->Delete(
                Type => 'Dashboard',
                Key  => $Self->{CacheKey} . '-Summary',
            );
        }
    }

    my %TicketSearchSummary;
    PROFILE:
    for my $SearchProfileName ( sort keys %SearchProfiles ) {

        my %CurrentSearchProfile = $SearchProfileObject->SearchProfileGet(
            Base      => 'TicketSearch',
            Name      => $SearchProfileName,
            UserLogin => $UserLogin,
        );
        next PROFILE if !$CurrentSearchProfile{Znuny4OTRSSaveDashboard};

        # prepare full text search
        if ( $CurrentSearchProfile{Fulltext} ) {
            $CurrentSearchProfile{ContentSearch} = 'OR';
            for my $Key (qw(From To Cc Subject Body)) {
                $CurrentSearchProfile{$Key} = $CurrentSearchProfile{Fulltext};
            }
        }

        $TicketSearchSummary{ $SearchProfileName } = \%CurrentSearchProfile;
    }
# ---

    return (
        Columns             => \@Columns,
        TicketSearch        => \%TicketSearch,
        TicketSearchSummary => \%TicketSearchSummary,
    );
}
# ---
# Znuny4OTRS-DashboardWidgetSearchProfile
# ---
# i can not explain why but in case of inherited sort functions
# we get in trouble with undefined sort params $a and $b.
# so i copied the _DefaultColumnSort function and renamed it to
# prevent inherited stuff and then it works.

sub _DefaultColumnSortTicketSearchProfile {
    my ( $Self, %Param ) = @_;

    my %DefaultColumns = (
        TicketNumber           => 100,
        Age                    => 110,
        Changed                => 111,
        PendingTime            => 112,
        EscalationTime         => 113,
        EscalationSolutionTime => 114,
        EscalationResponseTime => 115,
        EscalationUpdateTime   => 116,
        Title                  => 120,
        State                  => 130,
        Lock                   => 140,
        Queue                  => 150,
        Owner                  => 160,
        Responsible            => 161,
        CustomerID             => 170,
        CustomerName           => 171,
        CustomerUserID         => 172,
        Type                   => 180,
        Service                => 191,
        SLA                    => 192,
        Priority               => 193,
    );

    # set default order of ProcessManagement columns (for process widgets)
    if ( $Self->{Config}->{IsProcessWidget} ) {
        $DefaultColumns{"DynamicField_$Self->{ProcessManagementProcessID}"}  = 101;
        $DefaultColumns{"DynamicField_$Self->{ProcessManagementActivityID}"} = 102;
    }

    # dynamic fields can not be on the DefaultColumns sorting hash
    # when comparing 2 dynamic fields sorting must be alphabetical
    if ( !$DefaultColumns{$a} && !$DefaultColumns{$b} ) {
        return $a cmp $b;
    }

    # when a dynamic field is compared to a ticket attribute it must be higher
    elsif ( !$DefaultColumns{$a} ) {
        return 1;
    }

    # when a ticket attribute is compared to a dynamic field it must be lower
    elsif ( !$DefaultColumns{$b} ) {
        return -1;
    }

    # otherwise do a numerical comparison with the ticket attributes
    return $DefaultColumns{$a} <=> $DefaultColumns{$b};
}
# ---

1;

=back
