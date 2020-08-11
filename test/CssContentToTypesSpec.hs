module CssContentToTypesSpec where

import           Protolude

import           Test.Hspec

import qualified Data.Map as Map
import Data.Text (Text)
import qualified Data.Text as Text
import qualified Data.List as List
import Data.String.QQ
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Set.NonEmpty (NESet)
import qualified Data.Set.NonEmpty as NESet
import Data.Map (Map)
import qualified Data.Map as Map
import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.List.NonEmpty as NonEmpty

import Text.Regex.Base
import Text.RE.PCRE.Text

import Text.CSS.Parse
import CssContentToTypes
import Control.Arrow

cssContent :: Text
cssContent = [s|
.myButton {
  color: green;
}

.myButton > a {
  color: green;
}

.myButton2 > a {
  color: green;
}

a > .myButton5 {
  color: green;
}

.classInsideClass .classInsideClass2 {
  color: green;
}

.classWithBefore1:before {
  color: green;
}

.classWithBefore2Pre .classWithBefore2:before {
  color: green;
}

.classWithBefore3:before .classWithBefore3Post {
  color: var(--mycolor);
}

.classInOneLine{color: green;}

@media print {
  * {
    text-shadow: none !important;
    color: #000 !important;
    background-color: #fff !important;
  }

  a, a:visited { text-decoration: underline; }

  .myButton3 > a {
    color: green;
  }
}

@keyframes mdc-slider-emphasize {
  0% {
    -webkit-animation-timing-function: ease-out;
            animation-timing-function: ease-out;
  }
  50% {
    -webkit-animation-timing-function: ease-in;
            animation-timing-function: ease-in;
    -webkit-transform: scale(0.85);
            transform: scale(0.85);
  }
  100% {
    -webkit-transform: scale(0.571);
            transform: scale(0.571);
  }
}
.mdc-slider {
  position: relative;
  width: 100%;
  height: 48px;
  cursor: pointer;
  touch-action: pan-x;
  -webkit-tap-highlight-color: rgba(0, 0, 0, 0);
}

.mdc-slider-asdf:not(.mdc-slider--disabled) .mdc-slider__track {
  background-color: #018786;
  /* @alternate */
  background-color: var(--mdc-theme-secondary, #018786);
}

.xl\:animate-bounce {
  -webkit-animation: bounce 1s infinite;
          animation: bounce 1s infinite;
}

.sm\:animate-other {
  -webkit-animation: other 1s infinite;
          animation: other 1s infinite;
}

.sm\:nesting-level-1 {
  -webkit-animation: other 1s infinite;
          animation: other 1s infinite;
}

.sm\:nesting-level-1\:nesting-level-2 {
  -webkit-animation: other 1s infinite;
          animation: other 1s infinite;
}

.w-1\/2 {
  width: 50%;
}

.sm\:skew-y-12:hover:focus {
  --transform-skew-y: 12deg;
}

.-skew-y-6 {
  --transform-skew-y: -6deg;
}

|]

spec :: Spec
spec = do
  it "HistoryToInputsSpec" $ do
    let expected :: TailwindClasses =
          TailwindClasses
          ( Set.fromList
            [ OriginalName "classInOneLine"
            , OriginalName "-skew-y-6"
            , OriginalName "w-1\\/2"
            , OriginalName "classInsideClass"
            , OriginalName "classInsideClass2"
            , OriginalName "classWithBefore1"
            , OriginalName "classWithBefore2"
            , OriginalName "classWithBefore2Pre"
            , OriginalName "classWithBefore3"
            , OriginalName "classWithBefore3Post"
            , OriginalName "mdc-slider"
            , OriginalName "mdc-slider-asdf"
            , OriginalName "mdc-slider__track"
            , OriginalName "myButton"
            , OriginalName "myButton2"
            , OriginalName "myButton3"
            , OriginalName "myButton5"
            ]
          )
          ( Map.fromList
            [ ( ScopeName "Xl"
              , TailwindClasses
                ( Set.fromList
                  [ OriginalName "xl\\:animate-bounce"
                  ]
                )
                Map.empty
              )
            , ( ScopeName "Sm"
              , TailwindClasses
                ( Set.fromList
                  [ OriginalName "sm\\:animate-other"
                  , OriginalName "sm\\:nesting-level-1"
                  , OriginalName "sm\\:skew-y-12"
                  ]
                )
                ( Map.fromList
                  [ ( ScopeName "NestingLevel1"
                    , TailwindClasses
                      ( Set.fromList
                        [ OriginalName "sm\\:nesting-level-1\\:nesting-level-2"
                        ]
                      )
                      Map.empty
                    )
                  ]
                )
              )
            ]
          )

    -- for_ (cssContentToTypes cssContent) (putStrLn)

    cssContentToTypes cssContent `shouldBe` expected
