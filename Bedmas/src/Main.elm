module Main exposing (..)

import GraphicSVG exposing (..)
import GraphicSVG.EllieApp exposing(..)
import List
import String
import Dict exposing (Dict)
import Debug
import Html exposing (button)
import Html.Events exposing (onClick)

main = gameApp Tick { model = init, view = view, update = update, title = "Game Slot" }

view model = collage 250 150 (myShapes model)

-----------------------------------------------
---- this is where code from GameSlot goes ----
---- BUT MOVE "import"s above main         ----
-----------------------------------------------

-- Look at PaintInLines first!

-- DragAndDrop

-- Example of defining a list of words and target regions to drop them.

-- We need this as the first comment line, because we use the Dict module
-- Functions starting with Dict. are from that module.  See
--     https://package.elm-lang.org/packages/elm/core/latest/Dict

-- compile with
{-
➜  ExprTemplate git:(master) ✗ elm make src/Main.elm
Success!

    Main ───> index.html

➜  ExprTemplate git:(master) ✗ open index.html
-}

myShapes model =
  [ titleText |> move (-20, -20)
  , text "Which operation goes first?" |> txtFmt |> centered |> filled black |> move (0, 20)
  , exampleBox |> move (-20, 0)
  , expressionOptions model|> move (60, 10)
  , Debug.toString model.highlight |> text |> size 3 |> selectable |> filled black |> move (0,-30)
  , group [
    roundedRect 40 10 6 |> filled (rgba 150 133 182 0.5) |> move ( -70, -60 )
    , text "Hint" |> size 7 |> filled black |> move (-75, -62)
    ] |> move (20, 20) |> notifyTap (GiveHint)
  , text (model.hint) |> size 6 |> filled black |> move (-45, -30)
  , group [
    roundedRect 70 10 6 |> filled model.btnColor |> move ( 20, -60 )
    , text "New Equation" |> size 7 |> filled black |> move (3, -62)
    ] |> move (20, 20) |> notifyTap (SwitchEx)
  , text (model.hint) |> size 6 |> filled black |> move (-45, -30) ]
  ++ 
  -- what we draw depends on the state, this code generated by PALDraw
  if (model.highlight /= CNotHere)
        then [ Tuple.first <| display model.highlight (model.expr, red, identity)]
        else [ Tuple.first <| display model.highlight (model.expr, white, identity)]
  -- case model.state of
  --     Ex1 ->
  --          [ Tuple.first <| display model.highlight (model.expr, white, identity) ]
  --     Ex2 -> 
  --         if (model.expr == example2 && model.highlight == CSubtRight CExp)
  --         then [Tuple.first <| display model.highlight (example22, green, identity)]
  --         else if (model.expr == example22 && model.highlight == CSubt)
  --         then [ Tuple.first <| display model.highlight (example23, green, identity)]
  --         else if (model.expr == example2 && model.highlight == CSubt)
  --         then [ Tuple.first <| display model.highlight (model.expr, red, identity)]
  --         else [ Tuple.first <| display model.highlight (model.expr, white, identity)]
  --     Ex3 ->
  --       if (model.highlight /= CNotHere)
  --       then [ Tuple.first <| display model.highlight (model.expr, red, identity)]
  --       else [ Tuple.first <| display model.highlight (model.expr, white, identity)]

type Expr = Const Float | Plus Expr Expr | Subt Expr Expr | Mult Expr Expr | Div Expr Expr | Exp Expr Expr | Var String -- tree for expresions

type Clickable = CConst
               | CPlus | CPlusLeft Clickable | CPlusRight Clickable
               | CSubt | CSubtLeft Clickable | CSubtRight Clickable
               | CMult | CMultLeft Clickable | CMultRight Clickable
               | CDiv | CDivLeft Clickable | CDivRight Clickable
               | CExp | CExpLeft Clickable | CExpRight Clickable
               | CVar
               | CNotHere
               | Hint

example1 = Mult (Subt (Const 8) (Const 5)) (Const 3)
example12 = Mult (Const 3) (Const 3)
example13 = Const 9

example2 = Subt (Const 20) (Exp (Const 4)(Const 2))
example22 = Subt (Const 20) (Const 16)
example23 = (Const 4)

example3 = Mult (Const 3) (Subt (Plus (Exp (Const 2) (Const 2)) (Const 5)) (Const 6))
example32 = Mult (Const 3) (Subt (Plus (Const 4) (Const 5)) (Const 6))
example33 = Mult (Const 3) (Subt (Const 9) (Const 6))
example34 = Mult (Const 3) (Const 3)
example35 = Const 9

example4 = Div (Const 24) (Subt (Plus (Const 5) (Const 3)) (Const 4))
example42 = Div (Const 24) (Subt (Const 8) (Const 4))
example43 = Div (Const 24) (Const 4)
example44 = Const 6

exampleDec = Subt (Const 7.8) (Plus (Const 2.5) (Const 1.0))
exampleDec2 = Subt (Const 7.8) (Const 3.5)
exampleDec3 = Const 4.3

exampleFrac = Plus (Subt (Div (Const 4) (Const 8)) (Div (Const 15) (Const 45))) (Div (Const 2) (Const 3))
exampleFrac2 = Plus (Subt (Var " 1/2 ") (Div (Const 15) (Const 45))) (Div (Const 2) (Const 3))
exampleFrac3 = Plus (Subt (Var " 1/2 ") (Var " 1/3 ")) (Div (Const 2) (Const 3))
exampleFrac4 = Plus (Subt (Var " 1/2 ") (Var " 1/3 ")) (Var " 2/3 ")
exampleFrac5 = Plus (Var " 1/6") (Var " 2/3")
exampleFrac6= Var "5/6"

exampleVar = Plus (Mult (Const 7) (Var "x")) (Var "y")
exampleVar2 = Plus (Var "7x") (Var "y" )
exampleVar3 = Var "7x + y"

--exampleNInt = Const 4

-- text formatting
txtFmt stencil = stencil |> size 5 |> fixedwidth

-- width of one character (this is a guess, because it depends on browser)
charWidth = 9

-- highlight shape
backlit width colour = roundedRect width 6 4 |> filled colour |> makeTransparent 0.5 |> move (0,1)

display : Clickable         -- breadcrumbs to element to highlight
        -> (Expr, Color, Clickable -> Clickable)  -- (expr,breadcrumbs so far)
        -> (Shape Msg,Float) -- return shape, and width of shape
display highlight (expr0, col, mkClickable) =
  case expr0 of
      Const float -> -- probably assume positive
        let
            width = if float < 10 then charWidth
                else if float < 100 then 2*charWidth
                     else if float < 1000 then 3*charWidth
                          else 4*charWidth
        in
            ( group <|
              ( if highlight == CConst
                then (::) (backlit width col)
                else identity
              )
                [text (String.fromFloat float) |> txtFmt |> centered |> filled black ]
            , 1.1*width
            )

      Plus expr expr2 ->
        let
            (leftRecurse, rightRecurse)
              = case highlight of
                  CPlus ->
                    (CNotHere
                    ,CNotHere
                    )
                  CPlusLeft cl ->
                    (cl,CNotHere)
                  CPlusRight cl ->
                    (CNotHere,cl)
                  otherwise ->
                    (CNotHere
                    ,CNotHere
                    )
            (left,leftWidth) = display leftRecurse (expr,col, mkClickable << CPlusLeft)
            (right,rightWidth) = display rightRecurse (expr2,col, mkClickable << CPlusRight)

            hl = if highlight == CPlus
                  then [ backlit (leftWidth + rightWidth + charWidth) col |> move ( 0.5 * (rightWidth - leftWidth), 0)]
                  else []
        in
          ( group ( hl ++
                [
                  text "(" |> txtFmt |> centered |> filled black |> move (-0.125*charWidth - leftWidth, 0) 
                , left |> move (-0.5 * (0.25*charWidth + leftWidth),0)
                , text "+" |> txtFmt |> centered |> filled black
                , circle 3 |> filled (rgba 245 121 0 0.3) |> move (0,1) |> notifyTap (Tap <| mkClickable CPlus)
                , right |> move (0.5 * (0.25*charWidth+rightWidth),0)
                , text ")" |> txtFmt |> centered |> filled black |> move (0.125*charWidth + rightWidth,0)
                -- debug , rect (1*charWidth + leftWidth + rightWidth) 1 |> filled orange
                ]
            ) |> move ( 0.5 * (leftWidth - rightWidth), 0)
          , 1*charWidth + leftWidth + rightWidth )

      Subt expr expr2 -> 
        let
            (leftRecurse, rightRecurse)
              = case highlight of
                  CSubt ->
                    (CNotHere
                    ,CNotHere
                    )
                  CSubtLeft cl ->
                    (cl,CNotHere)
                  CSubtRight cl ->
                    (CNotHere,cl)
                  otherwise ->
                    (CNotHere
                    ,CNotHere
                    )
            (left,leftWidth) = display leftRecurse (expr, col, mkClickable << CSubtLeft)
            (right,rightWidth) = display rightRecurse (expr2, col, mkClickable << CSubtRight)

            hl = if highlight == CSubt
                  then [ backlit (leftWidth + rightWidth + charWidth) col |> move ( 0.5 * (rightWidth - leftWidth), 0)]
                  else []
        in
          ( group ( hl ++
                [
                  text "(" |> txtFmt |> centered |> filled orange |> move (-0.125*charWidth - leftWidth, 0)
                , left |> move (-0.5 * (0.25*charWidth + leftWidth),0)
                , text "-" |> txtFmt |> centered |> filled black
                , circle 3 |> filled (rgba 237 212 0 0.3) |> move (0,1) |> notifyTap (Tap <| mkClickable CSubt)
                , right |> move (0.5 * (0.25*charWidth+rightWidth),0)
                , text ")" |> txtFmt |> centered |> filled orange |> move (0.125*charWidth + rightWidth,0)
                -- debug , rect (1*charWidth + leftWidth + rightWidth) 1 |> filled orange
                ]
            ) |> move ( 0.5 * (leftWidth - rightWidth), 0)
          , 1*charWidth + leftWidth + rightWidth )
      
      Mult expr expr2 ->
        let
            (leftRecurse, rightRecurse)
              = case highlight of
                  CMult ->
                    (CNotHere
                    ,CNotHere
                    )
                  CMultLeft cl ->
                    (cl,CNotHere)
                  CMultRight cl ->
                    (CNotHere,cl)
                  otherwise ->
                    (CNotHere,CNotHere)

            (left,leftWidth) = display leftRecurse (expr, col, mkClickable << CMultLeft)
            (right,rightWidth) = display rightRecurse (expr2,col, mkClickable << CMultRight)

            hl = if highlight == CMult
                  then [ backlit (leftWidth + rightWidth + charWidth) col |> move ( 0.5 * (rightWidth - leftWidth), 0)]
                  else []
        in
          ( group ( hl ++
            [
              -- text "(" |> txtFmt |> centered |> filled black |> move (-0.125*charWidth - leftWidth, 0)
            left |> move (-0.5 * (0.25*charWidth + leftWidth),0)
            , text "*" |> txtFmt |> centered |> filled black
            , circle 3 |> filled (rgba 52 101 164 0.3) |> move (0,1) |> notifyTap (Tap <| mkClickable CMult)
            , right |> move (0.5 * (0.25*charWidth+rightWidth),0)
            -- , text ")" |> txtFmt |> centered |> filled black |> move (0.125*charWidth + rightWidth,0)
            -- debug , rect (1*charWidth + leftWidth + rightWidth) 1 |> filled red
            ]
            ) |> move ( 0.5 * (leftWidth - rightWidth), 0)
          , 1*charWidth + 0.8*leftWidth + 0.8*rightWidth )

      Div expr expr2 ->
        let
            (leftRecurse, rightRecurse)
              = case highlight of
                  CDiv ->
                    (CNotHere
                    ,CNotHere
                    )
                  CDivLeft cl ->
                    (cl,CNotHere)
                  CDivRight cl ->
                    (CNotHere,cl)
                  otherwise ->
                    (CNotHere,CNotHere)

            (left,leftWidth) = display leftRecurse (expr, col, mkClickable << CDivLeft)
            (right,rightWidth) = display rightRecurse (expr2,col, mkClickable << CDivRight)

            hl = if highlight == CDiv
                  then [ backlit (leftWidth + rightWidth + charWidth) col |> move ( 0.5 * (rightWidth - leftWidth), 0)]
                  else []
        in
          ( group ( hl ++
            [
              text "(" |> txtFmt |> centered |> filled black |> move (-0.125*charWidth - leftWidth, 0)
            , left |> move (-0.5 * (0.25*charWidth + leftWidth),0)
            , text "/" |> txtFmt |> centered |> filled black
            , circle 3 |> filled (rgba 117 80 123 0.3) |> move (0,1) |> notifyTap (Tap <| mkClickable CDiv)
            , right |> move (0.5 * (0.25*charWidth+rightWidth),0)
            , text ")" |> txtFmt |> centered |> filled black |> move (0.125*charWidth + rightWidth,0)
            -- debug , rect (1*charWidth + leftWidth + rightWidth) 1 |> filled red
            ]
            ) |> move ( 0.5 * (leftWidth - rightWidth), 0)
          , 1*charWidth + leftWidth + rightWidth )

      Exp expr expr2 ->
        let
            (leftRecurse, rightRecurse)
              = case highlight of
                  CExp ->
                    (CNotHere
                    ,CNotHere
                    )
                  CExpLeft cl ->
                    (cl,CNotHere)
                  CExpRight cl ->
                    (CNotHere,cl)
                  otherwise ->
                    (CNotHere,CNotHere)

            (left,leftWidth) = display leftRecurse (expr,col, mkClickable << CExpLeft)
            (right,rightWidth) = display rightRecurse (expr2,col, mkClickable << CExpRight)

            hl = if highlight == CExp
                  then [ backlit (leftWidth + rightWidth + charWidth) col |> move ( 0.5 * (rightWidth - leftWidth), 0)]
                  else []
        in
          ( group ( hl ++
            [
              -- text "(" |> txtFmt |> centered |> filled black |> move (-0.125*charWidth - leftWidth, 0)
            left |> move (-0.5 * (0.25*charWidth + leftWidth),0)
            , text "^" |> txtFmt |> centered |> filled black
            , circle 3 |> filled (rgba 255 105 180 0.3) |> move (0,1) |> notifyTap (Tap <| mkClickable CExp)
            , right |> move (0.5 * (0.25*charWidth+rightWidth),0)
            -- , text ")" |> txtFmt |> centered |> filled black |> move (0.125*charWidth + rightWidth,0)
            -- debug , rect (1*charWidth + leftWidth + rightWidth) 1 |> filled red
            ]
            ) |> move ( 0.5 * (leftWidth - rightWidth), 0)
          , 1*charWidth + 0.8*leftWidth + 0.8*rightWidth )

      Var string ->
        ( group <|  ( if highlight == CVar
                      then (::) (backlit charWidth col )
                      else identity
                    )
                    [text string |> txtFmt |> centered |> filled black]
        , charWidth )

type Msg = Tick Float GetKeyState
         | Tap Clickable
         | SetElement Element
         | SetState
         | GiveHint
         | SwitchEx

type State = Ex1
           | Ex2
           | Ex3
           | Ex4
           | ExD
           | ExF
           | ExV
           --| ExNI

type Simplify = Level0 | Level1 | Level2 | Level3 | Level4 | Done

update msg model =
    case msg of
        Tick t _ ->
            case (model.state, model.simplify) of
                -- Ex1  -> { model | time = t }
                (Ex1, Level0)  -> 
                    case (model.highlight) of 
                        (CMultLeft CSubt) -> { model | time = t, expr = example12, simplify = Level1 }
                        otherwise -> { model | time = t}
                (Ex1, Level1)  -> 
                    case (model.highlight) of 
                        (CMult) -> { model | time = t, expr = example13, simplify = Done, hint = "Good Job!", btnColor = (rgba 150 133 182 1)}
                        otherwise -> { model | time = t}

                (Ex2, Level0)  -> 
                    case (model.highlight) of 
                        (CSubtRight CExp) -> { model | time = t, expr = example22, simplify = Level1 }
                        otherwise -> { model | time = t}
                (Ex2, Level1) ->
                    case (model.highlight) of 
                        (CSubt) -> { model | time = t, expr = example23, simplify = Done, hint = "Good Job!", btnColor = (rgba 150 133 182 1) }
                        otherwise -> { model | time = t}

                (Ex3, Level0) ->
                    case (model.highlight) of
                      (CMultRight (CSubtLeft (CPlusLeft CExp))) -> { model | time = t, expr = example32, simplify = Level1}
                      otherwise -> {model | time = t}
                (Ex3, Level1) ->
                    case (model.highlight) of
                      (CMultRight (CSubtLeft CPlus)) -> { model | time = t, expr = example33, simplify = Level2}
                      otherwise -> {model | time = t}
                (Ex3, Level2) ->
                    case (model.highlight) of
                      (CMultRight CSubt) -> { model | time = t, expr = example34, simplify = Level3}
                      otherwise -> {model | time = t}
                (Ex3, Level3) ->
                    case (model.highlight) of
                      (CMult) -> {model | time = t, expr = example35, simplify = Done, hint = "Good Job!", btnColor = (rgba 150 133 182 1)}
                      otherwise -> {model | time = t }

                (Ex4, Level0) ->
                    case (model.highlight) of
                      (CDivRight (CSubtLeft CPlus)) -> {model | time = t, expr = example42, simplify = Level1}
                      otherwise -> {model | time = t }
                (Ex4, Level1) ->
                    case (model.highlight) of
                      (CDivRight CSubt) -> {model | time = t, expr = example43, simplify = Level2}
                      otherwise -> {model | time = t }
                (Ex4, Level2) ->
                    case (model.highlight) of
                      (CDiv) -> {model | time = t, expr = example44, simplify = Done, hint = "Good Job!", btnColor = (rgba 150 133 182 1)}
                      otherwise -> {model | time = t }

                (ExD, Level0) ->
                    case (model.highlight) of 
                      (CSubtRight CPlus) -> {model | time = t, expr = exampleDec2, simplify = Level1 }
                      otherwise -> {model | time = t }
                (ExD, Level1) ->
                    case (model.highlight) of 
                      (CSubt) -> {model | time = t, expr = exampleDec3, simplify = Done, hint = "Good Job!", btnColor = (rgba 150 133 182 1) }
                      otherwise -> {model | time = t }

                (ExF, Level0) ->
                    case (model.highlight) of 
                      (CPlusLeft(CSubtLeft CDiv)) -> {model | time = t, expr = exampleFrac2, simplify = Level1 }
                      otherwise -> {model | time = t }
                (ExF, Level1) ->
                    case (model.highlight) of 
                      (CPlusLeft(CSubtRight CDiv)) -> {model | time = t, expr = exampleFrac3, simplify = Level2 }
                      otherwise -> {model | time = t }
                (ExF, Level2) ->
                    case (model.highlight) of 
                      (CPlusRight CDiv) -> {model | time = t, expr = exampleFrac4, simplify = Level3 }
                      otherwise -> {model | time = t }
                (ExF, Level3) ->
                    case (model.highlight) of 
                      (CPlusLeft CSubt) -> {model | time = t, expr = exampleFrac5, simplify = Level4 }
                      otherwise -> {model | time = t }
                (ExF, Level4) ->
                    case (model.highlight) of 
                      (CPlus) -> {model | time = t, expr = exampleFrac6, simplify = Done, hint = "Good Job!", btnColor = (rgba 150 133 182 1)}
                      otherwise -> {model | time = t }

                (ExV, Level0) ->
                    case (model.highlight) of 
                      (CPlusLeft CMult) -> {model | time = t, expr = exampleVar2, simplify = Level1 }
                      otherwise -> {model | time = t }
                (ExV, Level1) ->
                    case (model.highlight) of 
                      (CPlus) -> {model | time = t, expr = exampleVar3, simplify = Done, hint = "Good Job!", btnColor = (rgba 150 133 182 1) }
                      otherwise -> {model | time = t }

                otherwise -> { model | time = t }
        Tap clickable ->
          { model | highlight = clickable }
        SetElement element ->
            {model | element = element }
        SetState ->
            case (model.element) of
                (Constants) -> { model | state = Ex1, expr = example1 }
                (Decimals) -> { model | state = ExD, expr = exampleDec }
                (Fractions) -> { model | state = ExF, expr = exampleFrac }
                (Variables) -> { model | state = ExV, expr = exampleVar }
                --(Integers) -> { model | element = element, state = ExNI }
                otherwise -> { model | state = Ex1 }
        GiveHint ->
          case (model.simplify) of
            (Level0) ->
              case (model.state) of
                (Ex1) -> { model | hint = "In BEDMAS, the M goes before A" }
                (Ex2) -> { model | hint = "What goes first? E or S?" }
                (Ex3) -> { model | hint = "What does the E in BEDMAS stand for?" }
                (Ex4) -> { model | hint = "Look at the innermost brackets" }
                otherwise -> { model | hint = ""}
            (Level1) -> 
              case (model.state) of
                (Ex1) -> { model | hint = "What does the S in BEDMAS stand for?" }
                (Ex2) -> { model | hint = "What does the S in BEDMAS stand for?" }
                (Ex3) -> { model | hint = "What does the A in BEDMAS stand for?" }
                (Ex4) -> { model | hint = "What does the S in BEDMAS stand for?" }
                (ExD) -> {model | hint = "What does the S in BEDMAS stand for?" }
                (ExF) -> {model | hint = "What does the S in BEDMAS stand for?" }
                (ExV) -> {model | hint = "What does the S in BEDMAS stand for?" }
                --(ExNI) -> {model | hint = "What does the S in BEDMAS stand for?" }
            (Level2) -> 
              case (model.state) of
                (Ex3) -> { model | hint = "What does the S in BEDMAS stand for?" }
                (Ex4) -> { model | hint = "What does the D in BEDMAS stand for?" }
                otherwise -> { model | hint = "" }
            (Level3) -> 
              case (model.state) of
                (Ex3) -> { model | hint = "What does the M in BEDMAS stand for?" }
                otherwise -> { model | hint = "" }
            otherwise -> { model | hint = "" }
        SwitchEx ->
          case (model.state) of
            (Ex1) -> { model | state = Ex2, expr = example2, simplify = Level0, hint="", btnColor = (rgba 150 133 182 0.5), element = Constants }
            (Ex2) -> { model | state = Ex4, expr = example4, simplify = Level0, hint="", btnColor = (rgba 150 133 182 0.5), element = Constants }
            (Ex3) -> { model | state = Ex1, expr = example1, simplify = Level0, hint="", btnColor = (rgba 150 133 182 0.5), element = Constants }
            (Ex4) -> { model | state = Ex3, expr = example3, simplify = Level0, hint="", btnColor = (rgba 150 133 182 0.5), element = Constants }
            otherwise -> { model | state = Ex1, expr = example1, simplify = Level0, hint="", btnColor = (rgba 150 133 182 0.5), element = Constants}

type alias Model =
    { time : Float
    , state : State
    , expr : Expr
    , simplify : Simplify
    , highlight : Clickable
    , element : Element
    , hint : String
    , btnColor : Color
    }

init : Model
init = { time = 0
       , state = Ex1
       , expr = example1
       , simplify = Level0
       , highlight = CNotHere
       , element = Constants
       , hint = ""
       , btnColor = (rgba 150 133 182 0.5)
       }

titleText = 
    group 
        [ text "B" |> serif |> size 15 |> filled black |> move ( -16*2 , 60 )
        , text "E" |> serif |> size 15 |> filled pink |> move ( -16, 60 )
        , text "D" |> serif |> size 15 |> filled purple |> move ( 0, 60 )
        , text "M" |> serif |> size 15 |> filled blue |> move ( 16, 60 )
        , text "A" |> serif |> size 15 |> filled orange |> move ( 16*2, 60 )
        , text "S" |> serif |> size 15 |> filled yellow |> move ( 16*3, 60 )
        ]

exampleBox =
    group
        [ rect 40 40|> filled (rgba 26 148 49 0.5) |> addOutline (solid 0.5) lightGrey |> move ( -70, 0 )
        , rect 20 8|> filled white |> addOutline (solid 0.5) lightGrey |> move ( -70, 20 )
        , text "Example" |> serif |> italic |> bold |> size 4 |> filled (rgba 26 148 49 0.5) |> move ( -77, 18 )
        , text "20 - 3 * (2 + 4 / 2)" |> size 4 |> filled black |> move ( -85, 8 )
        , text "= 20 - 3 * (2 + 2)" |> size 4 |> filled black |> move ( -83, 3 )
        , text "= 20 - 3 * (4)" |> size 4 |> filled black |> move ( -83, -2 )
        , text "= 20 - 12" |> size 4 |> filled black |> move ( -83, -7 )
        , text "= 8" |> size 4 |> filled black |> move ( -83, -12 )
        ]

expressionOptions model =
    group 
        [ text "Modify the Expression" |> fixedwidth |> size 4 |> bold |> filled black 
        , group <|
            List.map2
                (\el y ->
                    elemString model el
                        |> text
                        |> fixedwidth
                        |> size 3
                        |> filled black
                        |> notifyTap (SetElement el)
                        |> notifyTap SetState
                        |> move ( 0, -4 )
                        |> time1 model el 30 4
                        |> move ( 0, y )
                )
                [ Constants, Decimals, Fractions, Variables]
        (List.map (\x -> -4 * Basics.toFloat x) (List.range 0 20))
        ]

elemString m elem = 
    case elem of 
        Constants ->
            "Constants"
        Decimals -> 
            "Decimals"
        Fractions -> 
            "Fractions"
        Variables ->
            "Variables"
        Integers ->
            "Integers"

time1 model ss w h shape =
    if ss == model.element then
        group [ rect w h |> filled (rgba 255 185 179 (0.6 + 0.4 * sin (5 * model.time - 1))) |> move (15, -3), shape ]
    else
        shape

type Element 
    =  Constants
    | Decimals
    | Fractions
    | Variables
    | Integers

{- onOver : (Event -> msg) -> Attribute msg
onOver = 42
-}
