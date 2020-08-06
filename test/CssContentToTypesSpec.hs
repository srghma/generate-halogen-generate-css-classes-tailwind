module CssContentToTypesSpec where

import           Protolude

import           Test.Hspec

import qualified Data.Map as Map
import Data.Text (Text)
import qualified Data.Text as Text
import qualified Data.List as List
import Data.String.QQ

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

|]

spec :: Spec
spec = do
  it "HistoryToInputsSpec" $ do
    let (expected :: [Text]) = ["classInOneLine","classInsideClass","classInsideClass2","classWithBefore1","classWithBefore2","classWithBefore2Pre","classWithBefore3","classWithBefore3Post","mdc-slider","mdc-slider-asdf","mdc-slider__track","myButton","myButton2","myButton3","myButton5", "sm\\:animate-other","xl\\:animate-bounce"]
    -- for_ (cssContentToTypes cssContent) (putStrLn)
    cssContentToTypes cssContent `shouldBe` expected
