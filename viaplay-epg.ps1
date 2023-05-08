#-----------------------------------------------------------------------------------------
# Viaplay_EPG
#-----------------------------------------------------------------------------------------
Function viaplay_epg($channel){

    #xml: tv -> channel
    $global:xmlWriter.WriteStartElement("channel") 
    $global:xmlWriter.WriteAttributeString("id", $channel.id)
        $global:xmlWriter.WriteElementString("display-name", $channel.name)
        $global:xmlWriter.WriteElementString("display-name", $channel.desc)
        #icon
        $global:xmlWriter.WriteStartElement("icon")
            $global:xmlWriter.WriteAttributeString("src", $channel.icon)
            $global:xmlWriter.WriteAttributeString("height", $channel.height)
            $global:xmlWriter.WriteAttributeString("width", $channel.width)
        $global:xmlWriter.WriteFullEndElement()
    $global:xmlWriter.WriteFullEndElement()


    #Viaplay=EPG
    $data = Invoke-RestMethod -Uri "$($channel.url)?date=$($global:now)"
    $blocks = $data._embedded."viaplay:blocks"

    $count=0
    foreach( $block in $blocks ){
        if( $block.type -eq "list" ){
            $products = $block._embedded."viaplay:products"
            foreach( $product in $products ){
                if( $product.type -eq "sport" -and $product.content.originalTitle -ne "Studio" ){
                    $start = Get-Date $product.epg.start -Format "yyyyMMddHHmmss"
                    $end = Get-Date $product.epg.end -Format "yyyyMMddHHmmss"

                    #filter
                    $add = $true
                    if( $channel.filter ){
                        if( $channel.filter.in.length -gt 0 ){
                            if( $product.content.title -inotmatch $channel.filter.in ){
                                $add = $false
                            }
                        } elseif( $channel.filter.out.length -gt 0 ){
                            foreach( $out in $channel.filter.out ){
                                if( $product.content.title -imatch  $out ){ $add = $false; }
                            }
                        }
                    }
                    if( $add ){
                        #LOG
                        Write-Host "Block[$($count)] -> GUID: $($product.system.guid)"
                        Write-Host "Title: $($product.content.title)"
                        Write-Host "Title2: $($product.content.originalTitle)"
                        Write-Host "Desc: $($product.content.description.editorial)"
                        Write-Host "Start: $($start) End: $($end)"
                        Write-Host "Filter: in($($channel.filter.in)) out($($channel.filter.out))"
                        Write-Host ""

                        #xml: tv -> programme
                        $global:xmlWriter.WriteStartElement("programme")
                        $global:xmlWriter.WriteAttributeString("channel", $channel.id)
                        $global:xmlWriter.WriteAttributeString("start", "$($start) +0000")
                        $global:xmlWriter.WriteAttributeString("stop", "$($end) +0000")

                            #title
                            $global:xmlWriter.WriteStartElement("title")
                                $global:xmlWriter.WriteAttributeString("lang", "nl")
                                $global:xmlWriter.WriteString($product.content.title);
                            $global:xmlWriter.WriteFullEndElement()
                            
                            #sub-title
                            $global:xmlWriter.WriteStartElement("sub-title")
                                $global:xmlWriter.WriteAttributeString("lang", "nl")
                                $global:xmlWriter.WriteString($product.content.originalTitle);
                            $global:xmlWriter.WriteFullEndElement()
                            
                            #desc
                            $global:xmlWriter.WriteStartElement("desc")
                                $global:xmlWriter.WriteAttributeString("lang", "nl")
                                $global:xmlWriter.WriteString($product.content.description.editorial);
                            $global:xmlWriter.WriteFullEndElement()

                            #credits
                            $global:xmlWriter.WriteStartElement("credits")
                            $global:xmlWriter.WriteFullEndElement()

                            #category
                            foreach( $category in $channel.categories ){
                                $global:xmlWriter.WriteStartElement("category")
                                    $global:xmlWriter.WriteAttributeString("lang", "en")
                                    $global:xmlWriter.WriteString($category);
                                $global:xmlWriter.WriteFullEndElement()
                            }

                            #episode-num
                            $global:xmlWriter.WriteStartElement("episode-num")
                                $global:xmlWriter.WriteAttributeString("system", "dd_progid")
                                $global:xmlWriter.WriteString($product.system.guid);
                            $global:xmlWriter.WriteFullEndElement()
                            if( $product.content.originalTitle ){
                                $global:xmlWriter.WriteStartElement("episode-num")
                                    $global:xmlWriter.WriteAttributeString("system", "onscreen")
                                    $global:xmlWriter.WriteString($product.content.originalTitle);
                                $global:xmlWriter.WriteFullEndElement()
                            }

                            #language
                            $global:xmlWriter.WriteElementString("language", "nl")

                            #icon
                            if( $boxart ){
                                $global:xmlWriter.WriteStartElement("icon")
                                    $global:xmlWriter.WriteAttributeString("src", $product.content.images.boxart.url)
                                    $global:xmlWriter.WriteAttributeString("width", "199")
                                    $global:xmlWriter.WriteAttributeString("height", "298")
                                $global:xmlWriter.WriteFullEndElement()
                            }
                            if( $landscape ){
                                $global:xmlWriter.WriteStartElement("icon")
                                    $global:xmlWriter.WriteAttributeString("src", $product.content.images.landscape.url)
                                    $global:xmlWriter.WriteAttributeString("width", "960")
                                    $global:xmlWriter.WriteAttributeString("height", "540")
                                $global:xmlWriter.WriteFullEndElement()
                            }

                            #video
                            $global:xmlWriter.WriteStartElement("video")
                            $global:xmlWriter.WriteFullEndElement()
                            
                            #audio
                            $global:xmlWriter.WriteStartElement("audio")
                            $global:xmlWriter.WriteFullEndElement()

                        $global:xmlWriter.WriteFullEndElement()
                    }
                }
            }
        }
        $count++
    }

}
#-----------------------------------------------------------------------------------------



#date
$global:now = Get-Date -Format "yyyy-MM-dd"



#-----------------------------------------------------------------------------------------
# XMLTV
#-----------------------------------------------------------------------------------------
#xml: create / tv
$path = "F:\__PS\Viaplay-EPG\viaplay.xml"
$destination = "A:\xteve\guide2go"
$xmlsettings = New-Object System.Xml.XmlWriterSettings
$xmlsettings.Indent = $true
$global:xmlWriter = [System.XML.XmlWriter]::Create($path, $xmlsettings)
$global:xmlWriter.WriteStartElement("tv")


#channel: Formule 1 - Algemeen
viaplay_epg -channel @{
    "id"            = "viaplay.f1";
    "name"          = "VIAPLAYF1";
    "desc"          = "Viaplay Formule 1";
    "icon"          = "http://10.0.0.41/channels/channels_Viaplay_F1.png";  "width"="220"; "height"="134";
    "categories"    = @( "Auto racing"; "Sports talk"; "Sport"; "sport" );
    "url"           = "https://content.viaplay.com/pcdash-nl/sport/motorsport/formula-1";
    "filter"        = @{
                        "in"="";
                        "out"=@( "onboard"; "Backup Feed"; "Timing"; "Track Positioning"; "Pitlane"; "Shakedown" )
                    }
}
#channel: Formule 1 - Backup Feed
viaplay_epg -channel @{
    "id"            = "viaplay_backupfeed.f1";
    "name"          = "VIAPLAYBFF1";
    "desc"          = "Viaplay Formule 1 - Backup Feed";
    "icon"          = "http://10.0.0.41/channels/channels_Viaplay_F1.png";  "width"="220"; "height"="134";
    "categories"    = @( "Auto racing"; "Sports talk"; "Sport"; "sport" );
    "url"           = "https://content.viaplay.com/pcdash-nl/sport/motorsport/formula-1";
    "filter"        = @{
                        "in"="Backup Feed";
                        "out"=@()
                    }
}
#channel: Formule 1 - Timing
viaplay_epg -channel @{
    "id"            = "viaplay_timing.f1";
    "name"          = "VIAPLAYTF1";
    "desc"          = "Viaplay Formule 1 - Timing";
    "icon"          = "http://10.0.0.41/channels/channels_Viaplay_F1.png";  "width"="220"; "height"="134";
    "categories"    = @( "Auto racing"; "Sports talk"; "Sport"; "sport" );
    "url"           = "https://content.viaplay.com/pcdash-nl/sport/motorsport/formula-1";
    "filter"        = @{
                        "in"="Timing";
                        "out"=@()
                    }
}
#channel: Formule 1 - Track Positioning
viaplay_epg -channel @{
    "id"            = "viaplay_trackpos.f1";
    "name"          = "VIAPLAYTPF1";
    "desc"          = "Viaplay Formule 1 - Track Positioning";
    "icon"          = "http://10.0.0.41/channels/channels_Viaplay_F1.png";  "width"="220"; "height"="134";
    "categories"    = @( "Auto racing"; "Sports talk"; "Sport"; "sport" );
    "url"           = "https://content.viaplay.com/pcdash-nl/sport/motorsport/formula-1";
    "filter"        = @{
                        "in"="Track Positioning";
                        "out"=@()
                    }
}
#channel: Formule 1 - Pitlane
viaplay_epg -channel @{
    "id"            = "viaplay_pitlane.f1";
    "name"          = "VIAPLAYPF1";
    "desc"          = "Viaplay Formule 1 - Pitlane";
    "icon"          = "http://10.0.0.41/channels/channels_Viaplay_F1.png";  "width"="220"; "height"="134";
    "categories"    = @( "Auto racing"; "Sports talk"; "Sport"; "sport" );
    "url"           = "https://content.viaplay.com/pcdash-nl/sport/motorsport/formula-1";
    "filter"        = @{
                        "in"="Pitlane";
                        "out"=@()
                    }
}
#channel: Formule 1 - Bottas Onboard
viaplay_epg -channel @{
    "id"            = "viaplay_onboard_bottas.f1";
    "name"          = "VIAPLAYOBBF1";
    "desc"          = "Viaplay Formule 1 - Bottas Onboard";
    "icon"          = "http://10.0.0.41/channels/channels_Viaplay_F1.png";  "width"="220"; "height"="134";
    "categories"    = @( "Auto racing"; "Sports talk"; "Sport"; "sport" );
    "url"           = "https://content.viaplay.com/pcdash-nl/sport/motorsport/formula-1";
    "filter"        = @{
                        "in"="Bottas Onboard";
                        "out"=@()
                    }
}
#channel: Formule 1 - Magnussen Onboard
viaplay_epg -channel @{
    "id"            = "viaplay_onboard_magnussen.f1";
    "name"          = "VIAPLAYOBMF1";
    "desc"          = "Viaplay Formule 1 - Magnussen Onboard";
    "icon"          = "http://10.0.0.41/channels/channels_Viaplay_F1.png";  "width"="220"; "height"="134";
    "categories"    = @( "Auto racing"; "Sports talk"; "Sport"; "sport" );
    "url"           = "https://content.viaplay.com/pcdash-nl/sport/motorsport/formula-1";
    "filter"        = @{
                        "in"="Magnussen Onboard";
                        "out"=@()
                    }
}
#channel: Formule 1 - Verstappen Onboard
viaplay_epg -channel @{
    "id"            = "viaplay_onboard_verstappen.f1";
    "name"          = "VIAPLAYOBVF1";
    "desc"          = "Viaplay Formule 1 - Verstappen Onboard";
    "icon"          = "http://10.0.0.41/channels/channels_Viaplay_F1.png";  "width"="220"; "height"="134";
    "categories"    = @( "Auto racing"; "Sports talk"; "Sport"; "sport" );
    "url"           = "https://content.viaplay.com/pcdash-nl/sport/motorsport/formula-1";
    "filter"        = @{
                        "in"="Verstappen Onboard";
                        "out"=@()
                    }
}
#channel: Formule 1 - Onboard MIxed
viaplay_epg -channel @{
    "id"            = "viaplay_onboard_mixed.f1";
    "name"          = "VIAPLAYOBMXF1";
    "desc"          = "Viaplay Formule 1 - Onboard MIxed";
    "icon"          = "http://10.0.0.41/channels/channels_Viaplay_F1.png";  "width"="220"; "height"="134";
    "categories"    = @( "Auto racing"; "Sports talk"; "Sport"; "sport" );
    "url"           = "https://content.viaplay.com/pcdash-nl/sport/motorsport/formula-1";
    "filter"        = @{
                        "in"="Onboard MIxed";
                        "out"=@()
                    }
}
#channel: Formule 1 - Shakedown
viaplay_epg -channel @{
    "id"            = "viaplay_shakedown.f1";
    "name"          = "VIAPLAYSF1";
    "desc"          = "Viaplay Formule 1 - Shakedown";
    "icon"          = "http://10.0.0.41/channels/channels_Viaplay_F1.png";  "width"="220"; "height"="134";
    "categories"    = @( "Auto racing"; "Sports talk"; "Sport"; "sport" );
    "url"           = "https://content.viaplay.com/pcdash-nl/sport/motorsport/formula-1";
    "filter"        = @{
                        "in"="Shakedown";
                        "out"=@()
                    }
}

#channel: Premiere-League
viaplay_epg -channel @{
    "id"            = "viaplay.premiereleague";
    "name"          = "VIAPLAYPL";
    "desc"          = "Viaplay Premiere-League";
    "icon"          = "http://10.0.0.41/channels/channels_Viaplay_Premiere-League.png";  "width"="220"; "height"="134";
    "categories"    = @( "Soccer"; "Sports talk"; "Sport"; "sport" );
    "url"           = "https://content.viaplay.com/pcdash-nl/sport/voetbal/premier-league"
}

#channel: Bundesliga
viaplay_epg -channel @{
    "id"            = "viaplay.bundesliga";
    "name"          = "VIAPLAYB1";
    "desc"          = "Viaplay Bundesliga";
    "icon"          = "http://10.0.0.41//channels/channels_Viaplay_Bundesliga.png";  "width"="220"; "height"="134";
    "categories"    = @( "Soccer"; "Sports talk"; "Sport"; "sport" );
    "url"           = "https://content.viaplay.com/pcdash-nl/sport/voetbal/bundesliga"
}

#channel: Bundesliga 2
viaplay_epg -channel @{
    "id"            = "viaplay.bundesliga2";
    "name"          = "VIAPLAYB2";
    "desc"          = "Viaplay Bundesliga 2";
    "icon"          = "http://10.0.0.41//channels/channels_Viaplay_Bundesliga2.png";  "width"="220"; "height"="134";
    "categories"    = @( "Soccer"; "Sports talk"; "Sport"; "sport" );
    "url"           = "https://content.viaplay.com/pcdash-nl/sport/voetbal/2-bundesliga"
}

#channel: Darts
viaplay_epg -channel @{
    "id"            = "viaplay.darts";
    "name"          = "VIAPLAYD";
    "desc"          = "Viaplay Darts";
    "icon"          = "http://10.0.0.41//channels/channels_Viaplay_Darts.png";  "width"="220"; "height"="134";
    "categories"    = @( "Darts"; "Sports talk"; "Sport"; "sport" );
    "url"           = "https://content.viaplay.com/pcdash-nl/sport/darts/darts"
}


#xml-close
$global:xmlWriter.WriteFullEndElement()
$global:xmlWriter.Flush()
$global:xmlWriter.Close()
#-----------------------------------------------------------------------------------------



#-----------------------------------------------------------------------------------------
# XMLTV - Output => Xteve
#-----------------------------------------------------------------------------------------
Copy-Item $path -Destination $destination
#-----------------------------------------------------------------------------------------