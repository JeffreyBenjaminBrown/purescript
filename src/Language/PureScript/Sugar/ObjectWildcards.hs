-----------------------------------------------------------------------------
--
-- Module      :  Language.PureScript.Sugar.ObjectWildcards
-- Copyright   :  (c) 2013-14 Phil Freeman, (c) 2014 Gary Burgess, and other contributors
-- License     :  MIT
--
-- Maintainer  :  Phil Freeman <paf31@cantab.net>, Gary Burgess <gary.burgess@gmail.com>
-- Stability   :  experimental
-- Portability :
--
-- |
--
-----------------------------------------------------------------------------

module Language.PureScript.Sugar.ObjectWildcards (
  desugarObjectConstructors
) where

import Control.Arrow (second)

import Data.List (partition)
import Data.Maybe (isJust, fromJust)

import Language.PureScript.AST
import Language.PureScript.Names

desugarObjectConstructors :: Module -> Module
desugarObjectConstructors (Module mn ds exts) = Module mn (map desugarDecl ds) exts
  where

  desugarDecl :: Declaration -> Declaration
  (desugarDecl, _, _) = everywhereOnValues id desugarExpr id

  desugarExpr :: Expr -> Expr
  desugarExpr (ObjectConstructor ps) = wrapLambda ObjectLiteral ps
  desugarExpr (ObjectUpdater obj ps) = wrapLambda (ObjectUpdate obj) ps
  desugarExpr (ObjectGetter prop) =
    Abs (Left (Ident "obj")) (Accessor prop (Var (Qualified Nothing (Ident "obj"))))
  desugarExpr e = e

  wrapLambda :: ([(String, Expr)] -> Expr) -> [(String, Maybe Expr)] -> Expr
  wrapLambda mkVal ps =
    let (props, args) = partition (isJust . snd) ps
    in if null args
       then mkVal $ second fromJust `map` props
       else foldr (Abs . Left . Ident . fst) (mkVal (mkProp `map` ps)) args

  mkProp :: (String, Maybe Expr) -> (String, Expr)
  mkProp (name, Just e) = (name, e)
  mkProp (name, Nothing) = (name, Var (Qualified Nothing (Ident name)))