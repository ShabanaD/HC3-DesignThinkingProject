module Main exposing (..)

import GraphicSVG exposing (..)
import GraphicSVG.EllieApp exposing(..)
import List
import String
import Dict exposing (Dict)
import Debug

main = gameApp Tick { model = init, view = view, update = update, title = "Game Slot" }

view model = collage 192 128 (myShapes model)

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
  , text "Which operation goes first?" |> txtFmt |> centered |> filled black |> move (20, 20)
  , example |> move (5, 0)
  , Debug.toString model.highlight |> text |> selectable |> filled black |> move (0,-30) ]
  ++ 
  -- what we draw depends on the state, this code generated by PALDraw
  case model.state of
      Ex1 ->
           [ Tuple.first <| display model.highlight (model.expr, white, identity) ]
      Ex2 -> 
          if (model.expr == example2 && model.highlight == CSubtRight CExp)
          then [Tuple.first <| display model.highlight (example22, green, identity)]
          else if (model.expr == example22 && model.highlight == CSubt)
          then [ Tuple.first <| display model.highlight (example23, green, identity)]
          else if (model.expr == example2 && model.highlight == CSubt)
          then [ Tuple.first <| display model.highlight (model.expr, red, identity)]
          else [ Tuple.first <| display model.highlight (model.expr, white, identity)]

type Expr = Const Float | Plus Expr Expr | Subt Expr Expr | Mult Expr Expr | Div Expr Expr | Exp Expr Expr | Var String -- tree for expresions

type Clickable = CConst
               | CPlus | CPlusLeft Clickable | CPlusRight Clickable
               | CSubt | CSubtLeft Clickable | CSubtRight Clickable
               | CMult | CMultLeft Clickable | CMultRight Clickable
               | CDiv | CDivLeft Clickable | CDivRight Clickable
               | CExp | CExpLeft Clickable | CExpRight Clickable
               | CVar
               | CNotHere

example1 = Plus (Mult (Const 7) (Var "x")) (Var "y")
example12 = Plus (Var "7x") (Var "y" )
example13 = Var "7x + y"
example2 = Subt (Const 20) (Exp (Const 4)(Const 2))
example22 = Subt (Const 20) (Const 16)
example23 = (Const 4)

-- text formatting
txtFmt stencil = stencil |> size 4 |> fixedwidth

-- width of one character (this is a guess, because it depends on browser)
charWidth = 8

-- highlight shape
backlit width colour = roundedRect width 6 4 |> filled colour |> makeTransparent 0.5 |> move (0,1)

display : Clickable         -- breadcrumbs to element to highlight
        -> (Expr, Color, Clickable -> Clickable)  -- (expr,breadcrumbs so far)
        -> (Shape Msg,Float) -- return shape, and width of shape
display highlight (expr0,col, mkClickable) =
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
            , width
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
              text "(" |> txtFmt |> centered |> filled black |> move (-0.125*charWidth - leftWidth, 0)
            , left |> move (-0.5 * (0.25*charWidth + leftWidth),0)
            , text "*" |> txtFmt |> centered |> filled black
            , circle 3 |> filled (rgba 52 101 164 0.3) |> move (0,1) |> notifyTap (Tap <| mkClickable CMult)
            , right |> move (0.5 * (0.25*charWidth+rightWidth),0)
            , text ")" |> txtFmt |> centered |> filled black |> move (0.125*charWidth + rightWidth,0)
            -- debug , rect (1*charWidth + leftWidth + rightWidth) 1 |> filled red
            ]
            ) |> move ( 0.5 * (leftWidth - rightWidth), 0)
          , 1*charWidth + leftWidth + rightWidth )

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
              text "(" |> txtFmt |> centered |> filled black |> move (-0.125*charWidth - leftWidth, 0)
            , left |> move (-0.5 * (0.25*charWidth + leftWidth),0)
            , text "^" |> txtFmt |> centered |> filled black
            , circle 3 |> filled (rgba 255 105 80 0.3) |> move (0,1) |> notifyTap (Tap <| mkClickable CExp)
            , right |> move (0.5 * (0.25*charWidth+rightWidth),0)
            , text ")" |> txtFmt |> centered |> filled black |> move (0.125*charWidth + rightWidth,0)
            -- debug , rect (1*charWidth + leftWidth + rightWidth) 1 |> filled red
            ]
            ) |> move ( 0.5 * (leftWidth - rightWidth), 0)
          , 1*charWidth + leftWidth + rightWidth )

      Var string ->
        ( group <|  ( if highlight == CVar
                      then (::) (backlit charWidth col )
                      else identity
                    )
                    [text string |> txtFmt |> centered |> filled black]
        , charWidth )

type Msg = Tick Float GetKeyState
         | Tap Clickable

type State = Ex1
           | Ex2

type Simplify = Level0 | Level1 | Level2 | Level3 | Done

update msg model =
    case msg of
        Tick t _ ->
            case (model.state, model.simplify) of
                -- Ex1  -> { model | time = t }
                (Ex2, Level0)  -> 
                    case (model.highlight) of 
                        (CSubtRight CExp) -> { model | time = t, expr = example22, simplify = Level1 }
                        otherwise -> { model | time = t}
                (Ex2, Level1) ->
                    case (model.highlight) of 
                        (CSubt) -> { model | time = t, expr = example23, simplify = Done }
                        otherwise -> { model | time = t}
                        
                -- (Ex2,CSubt) -> { model | time = t,
                --   expr = example23 }
                otherwise -> { model | time = t }
        Tap clickable ->
          { model | highlight = clickable }
        -- CLICKFUNCTION State -> case State of
        --         state1 -> {model | expr = }

type alias Model =
    { time : Float
    , state : State
    , expr : Expr
    , simplify : Simplify
    , highlight : Clickable
    }

init : Model
init = { time = 0
       , state = Ex2
       , expr = example2
       , simplify = Level0
       , highlight = CNotHere
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

example =
    group
        [ rect 40 40|> filled (rgba 26 148 49 0.5) |> addOutline (solid 0.5) lightGrey |> move ( -70, 0 )
        , rect 20 8|> filled white |> addOutline (solid 0.5) lightGrey |> move ( -70, 20 )
        , text "Example" |> serif |> italic|> size 3 |> filled (rgba 26 148 49 0.5) |> move ( -75,20 )
        ]

{- onOver : (Event -> msg) -> Attribute msg
onOver = 42
-}
