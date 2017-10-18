module Main exposing (..)

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import List.Extra as Lex exposing (..)
import Debug exposing (..)


---- MODEL ----

type alias ClickableWord =
    { text: String
    , erased: Bool
    , position: Int
    }


type alias Model =
    { text: List ClickableWord
    }


initModel: Model
initModel = 
    { text = textToClickableWords dummyText
    }

init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )


dummyWords: List ClickableWord
dummyWords = 
    [ ClickableWord "TEST" False 1
    , ClickableWord "TEST" False 2
    , ClickableWord "TEST" False 3
    , ClickableWord "TEST" False 4
    , ClickableWord "TEST" False 5
    ]

dummyText: String 
dummyText = 
    """
    Lorem ipsum dolor sit amet, pro mandamus deterruisset ut, quo exerci audiam eu, 
    ad numquam lobortis duo. Est te erant causae detracto, graece mollis mea at, 
    laudem quaeque mei no. Et alterum impedit vituperata pri, per cu solet atomorum. 
    Nemore repudiare ad his, ipsum dolore ad eam, te audiam latine phaedrum pro. Eruditi 
    vivendo est an, choro labore voluptatibus ut qui. Cu legimus adversarium has, nulla 
    postulant usu et. In melius abhorreant cum.

    Ei mei malorum honestatis instructior, ne omnes quidam pro. Soluta lobortis deterruisset
    sed no, ius illud populo singulis eu. Vim modus soleat et, aperiam intellegam contentiones 
    at his, legendos torquatos nam id. Eu sit omnes ponderum disputando, vix epicurei suavitate te, 
    agam nibh omittam vim no. Vix mollis aliquip oporteat in.   

    Harum congue cu sea, eum in integre phaedrum repudiandae. Mei populo iisque commodo ei, vel
    te libris prompta signiferumque, errem assentior democritum eam ad. Justo expetendis pri ad, 
    sumo aperiri mentitum vix eu. Sumo veri vel ei, his libris commodo ea. Ius agam natum interpretaris 
    te, pro at saepe deserunt adipiscing, has quando fastidii te. Quo at probatus invenire, his scripta 
    phaedrum volutpat te, et quod diceret forensibus per.  

    In esse vide facilis nam, ex pri ubique noster impedit, mei te dicat falli blandit. Qui id dicant 
    voluptua. Feugait splendide intellegat quo in, qui ea harum veniam, idque mazim utamur has ea. Ubique 
    delectus an vix, velit tantas vis ei. Ei laudem intellegat vis, ne duis ludus dignissim mea. Solet 
    mollis regione ad vel.   

    Summo intellegat mea id. No usu vidit ignota elaboraret. Per labitur euismod assentior et, mutat 
    libris feugiat cu pri. Usu et mutat eripuit fabulas, singulis lobortis intellegam pro ex. Vel an stet 
    utamur instructior. Odio porro his no, ea has detracto antiopam.
    """

textToClickableWords: String -> List ClickableWord
textToClickableWords inputText = 
    let 
        rawWordsArray = String.split " " inputText
    in 
        List.map2 createWord rawWordsArray (List.range 1 <| List.length <| rawWordsArray)



createWord: String -> Int -> ClickableWord
createWord string int = 
    ClickableWord string False int 

---- UPDATE ----

eraseOrBringBack: ClickableWord -> ClickableWord 
eraseOrBringBack word = 
    case word.erased of 
        True -> 
            ClickableWord word.text False word.position
        False -> 
            ClickableWord word.text True word.position

hasPosition: Int -> ClickableWord -> Bool 
hasPosition int word = 
    if word.position == int then 
        True 
    else 
        False 

type Msg
    = ToggleWord ClickableWord


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of 
        ToggleWord word -> 
            let 
                newText = Lex.updateAt (word.position - 1) eraseOrBringBack model.text
            in 
                case newText of 
                    Just text -> 
                        ({model | text = text}, Cmd.none) 
                    Nothing -> 
                        Debug.crash "You're trying to toggle a word that doesn't exist."




---- VIEW ----

myStyles: Html.Attribute Msg 
myStyles = 
    style 
        [ ("font-family", "Georgia")
        ]

view : Model -> Html Msg
view model =
    div [myStyles]
        ( List.map displayClickableWord model.text )

displayClickableWord: ClickableWord -> Html Msg 
displayClickableWord word = 
    Html.span 
        ([onClick (ToggleWord word),  (style [("color", (wordColor word))]) ])
        [Html.text (word.text ++ " ") ]


wordColor: ClickableWord -> String
wordColor word = 
    case word.erased of 
        True -> 
            "whitesmoke"
        False -> 
            "black"


---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
