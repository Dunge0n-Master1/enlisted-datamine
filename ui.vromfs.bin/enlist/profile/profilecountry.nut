let { get_locale_country } = require("platform")

let countriesWithRecommendEmailRegistration = {
  AZ = "Azerbaijan"
  AM = "Armenia"
  BY = "Belarus"
  GE = "Georgia"
  KZ = "Kazakhstan"
  KG = "Kyrgyzstan"
  LV = "Latvia"
  LT = "Lithuania"
  MD = "Moldova"
  RU = "Russia"
  TJ = "Tajikistan"
  TM = "Turkmenistan"
  UZ = "Uzbekistan"
  UA = "Ukraine"
  EE = "Estonia"
}

return {
  isPlayerRecommendedEmailRegistration = @() get_locale_country().toupper() in countriesWithRecommendEmailRegistration
}