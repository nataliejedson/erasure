module Main exposing (..)

import Html exposing (Html, text, div, img)
import Html.Attributes as Hattr exposing (..)
import Html.Events exposing (onClick, onInput)
import List.Extra as Lex exposing (..)
import Random.Extra as Rex exposing (..)
import Random exposing (..)
import Debug exposing (crash)
import Loop exposing (..)




---- MODEL ----

type alias ClickableWord =
    { text: String
    , erased: Bool
    , position: Int
    }


type alias Model =
    { clickableText: List ClickableWord
    , textEntered: Bool
    , inputText: String
    , percentRandom: Int
    , seed: Random.Seed
    }


initModel: Model
initModel = 
    { clickableText = []
    , textEntered = False
    , inputText = ""
    , percentRandom = 90
    , seed = Random.initialSeed 42
    }

init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )



textToClickableWords: String -> List ClickableWord
textToClickableWords inputText = 
    let 
        rawWordsArray = String.split " " inputText
    in 
        List.map2 createWord rawWordsArray (List.range 1 <| List.length <| rawWordsArray)



createWord: String -> Int -> ClickableWord
createWord string int = 
    ClickableWord string False int 

--TODO create seed based on time in init 


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
    | MakeTextClickable String 
    | UpdateInputText String 
    | GoBackToTextEntry
    | Randomize
    | UpdatePercentRandom String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of 
        ToggleWord word -> 
            let 
                newText = Lex.updateAt (word.position - 1) eraseOrBringBack model.clickableText
            in 
                case newText of 
                    Just text -> 
                        ({model | clickableText = text}, Cmd.none) 
                    Nothing -> 
                        Debug.crash "You're trying to toggle a word that doesn't exist."

        MakeTextClickable text -> 

            let 
                clickableText = textToClickableWords model.inputText 
            in 
                ({ model 
                    | clickableText = clickableText
                    , textEntered = True
                    }
                , Cmd.none)

        UpdateInputText text -> 
            ({model | inputText = text}, Cmd.none)

        GoBackToTextEntry -> 
            ({model | textEntered = False}, Cmd.none)

        Randomize -> 
            ((randomErasure model), Cmd.none)

        UpdatePercentRandom string -> 
            ({model | percentRandom = (Result.withDefault 0 (String.toInt string)) }, Cmd.none)

desiredAmountErased: Model -> Int 
desiredAmountErased model = ((totalNumberOfWords model) * model.percentRandom)  // 100 -- Note use of integer division here 

currentErasedWords: Model -> List ClickableWord 
currentErasedWords model = List.filter (.erased) model.clickableText

currentAmountErased: Model -> Int 
currentAmountErased model = List.length (currentErasedWords model) 

totalNumberOfWords: Model -> Int 
totalNumberOfWords model = List.length model.clickableText 

randomIndex: Model -> Int
randomIndex model = randomIndexAndSeed model |> Tuple.first

newSeed: Model -> Random.Seed 
newSeed model = randomIndexAndSeed model |> Tuple.second

randomErasure: Model -> Model
randomErasure model = 
    let 
        words: List ClickableWord
        words = model.clickableText

        percent: Int
        percent = model.percentRandom

        desired: Int
        desired = desiredAmountErased model

        current: Int
        current = currentAmountErased model

        newModel = model

    in 
        if (current < desired) then
            randomErasure (eraseAWord model)
        else if (current == desired) then 
            model
        else  
            randomErasure (bringBackAWord model)

eraseAWord: Model -> Model 
eraseAWord model =
    let 
        erasedWord = eraseAtIndex (randomIndex model) model.clickableText
    in 
        case erasedWord of 
            Just newWords -> 
                { model | 
                    clickableText = newWords, 
                    seed = (newSeed model)
                }
            _ -> 
                { model | seed = (newSeed model) } --DEBUG?) 


bringBackAWord: Model -> Model
bringBackAWord model = 
            let 
                broughtBackWord = bringBackAtIndex (randomIndex model)  model.clickableText
            in 
                case broughtBackWord of 
                    Just newWords -> 
                        { model | 
                            clickableText = newWords, 
                            seed = (newSeed model)
                        }
                    _ -> 
                        { model | seed = (newSeed model) } --DEBUG?


randomIndexAndSeed: Model -> (Int, Seed) 
randomIndexAndSeed model = 
    let 
        total: Int 
        total = totalNumberOfWords model

        seed: Random.Seed
        seed = model.seed
    in 
        Random.step (Random.int 0 ((totalNumberOfWords model)-1)) seed

eraseAtIndex: Int -> List ClickableWord -> Maybe (List ClickableWord)
eraseAtIndex index words = 
    let 
        wordAtIndex = Lex.getAt index words

    in 
        case wordAtIndex of  
            Just word -> 
                case word.erased of 
                    True -> 
                        Just words 
                    False -> 
                        Lex.setAt index (eraseOrBringBack word) words
            Nothing -> 
                Debug.crash "No word at that index."

bringBackAtIndex: Int -> List ClickableWord -> Maybe (List ClickableWord)
bringBackAtIndex index words = 
    let 
        wordAtIndex = Lex.getAt index words

    in 
        case wordAtIndex of  
            Just word -> 
                case word.erased of 
                    True -> 
                        Lex.setAt index (eraseOrBringBack word) words
                    False -> 
                        Just words
            Nothing -> 
                Debug.crash "No word at that index."


isErased: ClickableWord -> Bool 
isErased word = 
    word.erased == True

isNotErased: ClickableWord -> Bool 
isNotErased word = 
    word.erased == False

---- VIEW ----

myStyles: List (Html.Attribute Msg) 
myStyles = 
    List.singleton 
        (style 
            [ ("font-family", "Georgia")
            , ("font-size", "20px")
            , ("display", "inline-block")
            , ("margin", "auto")
            ] )


view : Model -> Html Msg
view model =
    case model.textEntered of 
        False -> 
            enterYourTextScreen model
        True -> 
            div myStyles
                [ 
                    div 
                        [ 
                            style 
                                [ ("width", "75%")
                                , ("display", "inline-block")
                                , ("margin", "auto") 
                                , ("margin-top", "2em")
                                , ("margin-bottom", "1em")
                                ] 
                        ] 
                        (List.map displayClickableWord model.clickableText) 
                    , Html.br [] []
                    , Html.button (onClick GoBackToTextEntry :: appButtonStyle) [Html.text "Enter different text"]
                    , Html.br [][]
                    , Html.text "Erase ", percentRandomInput, Html.text "% of these words"
                    , Html.button ( onClick (Randomize) :: appButtonStyle) [Html.text "Randomize!"]
                    

                ] 

appButtonStyle: List (Html.Attribute Msg)
appButtonStyle = 
    style
        [ ("padding", "0 5px") 
        , ("border-radius", "0") 
        , ("border-width", "0") 
        , ("color", "black") 
        , ("background", "transparent") 
        , ("font-family", "'Arial', sans-serif")
        , ("padding-left", "6em")
        , ("padding-right", "6em")
        , ("margin-bottom", "30px")
        , ("display", "inline-block")  
        ]
    |> List.singleton

enterYourTextScreen: Model -> Html Msg 
enterYourTextScreen model = 
    div (myStyles)
        [ Html.br [] [] , Html.br [] []
        , Html.textarea 
            [ placeholder "Enter your text here"
            , onInput UpdateInputText
            , style [("width", "800px"), ("height", "200px") ]
            ] []
        , Html.br [] [] , Html.br [] [] 
        , Html.button ( onClick (MakeTextClickable model.inputText) :: appButtonStyle) [Html.text "Let's erase stuff!"]

        ]

percentRandomInput: Html Msg
percentRandomInput = 
      div []
    [ Html.input
      [ type_ "text"
      , size 3
      , onInput UpdatePercentRandom
      , style [("display", "inline-block")]
      ] []
    ]


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
