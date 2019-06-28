
{-
<TEST>
{- MISSING HASH #-} -- {-# MISSING HASH #-}
<COMMENT> {- INLINE X -}
{- INLINE Y -} -- {-# INLINE Y #-}
{- INLINE[~k] f -} -- {-# INLINE[~k] f #-}
{- NOINLINE Y -} -- {-# NOINLINE Y #-}
{- UNKNOWN Y -}
<COMMENT> INLINE X
</TEST>
-}
{-# LANGUAGE PackageImports #-}


module Hint.Comment(commentHint) where

import Hint.Type
import Data.Char
import Data.List.Extra
import Refact.Types(Refactoring(ModifyComment))
import "ghc-lib-parser" SrcLoc
import "ghc-lib-parser" ApiAnnotation
import GHC.Util

pragmas = words $
    "LANGUAGE OPTIONS_GHC INCLUDE WARNING DEPRECATED MINIMAL INLINE NOINLINE INLINABLE " ++
    "CONLIKE LINE SPECIALIZE SPECIALISE UNPACK NOUNPACK SOURCE"


commentHint :: CommentEx -> [Idea]
commentHint CommentEx {ghcComment=comm}
  | "#" `isSuffixOf` s && not ("#" `isPrefixOf` s) = [grab "Fix pragma markup" comm $ '#':s]
  | name `elem` pragmas = [grab "Use pragma syntax" comm $ "# " ++ trim s ++ " #"]
       where s = commentText comm
             name = takeWhile (\x -> isAlphaNum x || x == '_') $ dropWhile isSpace s
commentHint _ = []

grab :: String -> Located AnnotationComment -> String -> Idea
grab msg o@(L pos c) s2 =
  let s1 = commentText o in
  rawIdea Suggestion msg (ghcSpanToHSE pos) (f s1) (Just $ f s2) [] refact
    where f s = if isCommentMultiline o then "{-" ++ s ++ "-}" else "--" ++ s
          refact = [ModifyComment (toRefactSrcSpan (ghcSpanToHSE pos)) (f s2)]
