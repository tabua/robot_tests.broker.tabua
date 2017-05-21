*** Settings ***
Library  String
Library  Selenium2Library
Library  tabua_service.py
Library  DebugLibrary
Library  Collections
Library  BuiltIn


*** Variables ***

# Auction creation locators
${locator.title}                     id=prozorro_auction_title_ua                         # Lot number (name) according to DGF
${locator.description}               id=prozorro_auction_description_ua                   # Lot is going to be present on Auction
${locator.dgfid}                     id=prozorro_auction_dgf_id                           # dfgID field
${locator.value.amount}              id=prozorro_auction_value_attributes_amount          # Start Lot price
${locator.minimalStep.amount}        id=prozorro_auction_minimal_step_attributes_amount   # Minimal price step-up
${locator.guaranteeamount}           id=prozorro_auction_guarantee_attributes_amount      # Amount of Bank guarantee

${locator.delivery_zip}              xpath=//input[contains(@id, "prozorro_auction_items_attributes_") and contains(@id, "_postal_code")]
${locator.delivery_region}           xpath=//select[contains(@id, "prozorro_auction_items_attributes_") and contains(@id, "_region")]
${locator.delivery_country}          xpath=//select[contains(@id, "prozorro_auction_items_attributes_") and contains(@id, "_country_name")]
${locator.delivery_town}             xpath=//input[contains(@id, "prozorro_auction_items_attributes_") and contains(@id, "_locality")]
${locator.delivery_address}          xpath=//input[contains(@id, "prozorro_auction_items_attributes_") and contains(@id, "_street_address")]
${locator.add_item}                  xpath=//a[@class="button btn_white add_auction_item add_fields"]

${locator.publish}                     xpath=//input[@name="publish"]

${locator.tenderPeriod.endDate}           xpath=//span[@class="entry_submission_end_detail"]
${locator.view.minimalStep.amount}        xpath=//div[@class="blue_block"][2]//span[@class="amount"]

${locator.items[0].description}      css=div.small-7.columns.auction_description     # Description of Item (Lot in Auctions)
${locator.view.items[0].description}        xpath=//div[@class="columns blue_block items"]/ul/li[1]/div[@class="small-7 columns"]/div[@class="item_title"]
${locator.view.items[1].description}        xpath=//div[@class="columns blue_block items"]/ul/li[2]/div[@class="small-7 columns"]/div[@class="item_title"]
${locator.view.items[2].description}        xpath=//div[@class="columns blue_block items"]/ul/li[3]/div[@class="small-7 columns"]/div[@class="item_title"]

${locator.view.value.amount}         xpath=//span[@class="amount"]


*** Keywords ***

Підготувати клієнт для користувача
  [Arguments]  @{ARGUMENTS}
  [Documentation]  Відкрити браузер, створити об’єкт api wrapper, тощо
  ...      ${ARGUMENTS[0]} ==  username
  Open Browser
  ...      ${USERS.users['${ARGUMENTS[0]}'].homepage}
  ...      ${USERS.users['${ARGUMENTS[0]}'].browser}
  ...      alias=${ARGUMENTS[0]}
  Set Window Size   @{USERS.users['${ARGUMENTS[0]}'].size}
  Set Window Position   @{USERS.users['${ARGUMENTS[0]}'].position}
  Run Keyword If   '${ARGUMENTS[0]}' != 'tabua_Viewer'   Login    ${ARGUMENTS[0]}


Login
  [Arguments]  @{ARGUMENTS}
#  Logs in as Auction owner, who can create Fin auctions
  Wait Until Page Contains Element   id=user_password   20
  Input Text   id=user_email   ${USERS.users['${ARGUMENTS[0]}'].login}
  Input Text   id=user_password   ${USERS.users['${ARGUMENTS[0]}'].password}
  Click Element   xpath=//input[@type="submit"]
  Sleep     2
  Go To  ${BROKERS['tabua'].startpage}
  Wait Until Page Contains Element   xpath=//span[@class="button menu_btn is_logged"]   20
  Sleep     2
  Log To Console   Success logging in as Some one - ${ARGUMENTS[0]}


Оновити сторінку з тендером
  [Arguments]  ${user_name}  ${tender_id}
  Switch Browser	${user_name}
  Reload Page
  Sleep    3s

Підготувати дані для оголошення тендера
  [Arguments]  ${username}  ${tender_data}  ${role_name}
  ${tender_data}=   update_test_data   ${role_name}   ${tender_data}
  [Return]   ${tender_data}


Створити тендер
  [Arguments]  @{ARGUMENTS}
  [Documentation]
  ...      ${ARGUMENTS[0]} ==  username
  ...      ${ARGUMENTS[1]} ==  tender_data
# Initialisation. Getting values from Dictionary
  Log To Console    Start creating procedure

  ${title}=         Get From Dictionary   ${ARGUMENTS[1].data}               title
  ${description}=   Get From Dictionary   ${ARGUMENTS[1].data}               description
  ${dgfID}=         Get From Dictionary   ${ARGUMENTS[1].data}               dgfID
  ${budget}=        Get From Dictionary   ${ARGUMENTS[1].data.value}         amount
  ${guarantee}=     Get From Dictionary   ${ARGUMENTS[1].data.guarantee}     amount
  ${step_rate}=     Get From Dictionary   ${ARGUMENTS[1].data.minimalStep}   amount
  ${dgfDecisionID}=     Get From Dictionary   ${ARGUMENTS[1].data}        dgfDecisionID
  ${dgfDecisionDate}=   Get From Dictionary   ${ARGUMENTS[1].data}        dgfDecisionDate
  ${tenderAttempts}=    Get From Dictionary   ${ARGUMENTS[1].data}        tenderAttempts

# Date of auction start
  ${start_date}=    Get From Dictionary   ${ARGUMENTS[1].data.auctionPeriod}    startDate
  Go To  ${BROKERS['tabua'].auctionpage}
  Wait Until Page Contains Element   xpath=//a[contains(text(), "Створити новий аукціон")]   20
  Click Link                         xpath=//a[contains(text(), "Створити новий аукціон")]
# Selecting DGF Financial asset or DGF Other assets
  Wait Until Page Contains Element   xpath=//label[@for="prozorro_auction_procurement_method_type_dgf_financial_assets"]   20
  Run Keyword If  '${mode}' == 'dgfFinancialAssets'  Click Element   xpath=//label[@for="prozorro_auction_procurement_method_type_dgf_financial_assets"]
  Run Keyword If  '${mode}' == 'dgfOtherAssets'      Click Element   xpath=//label[@for="prozorro_auction_procurement_method_type_dgf_other_assets"]
  Log To Console    Selecting Some procedure ${mode}
# Input fields tender
  Input Text   ${locator.title}              ${title}
  Input Text   ${locator.description}        ${description}
  Input Text   ${locator.dgfid}              ${dgfID}
# New fields add
  Input Text   xpath=//input[@id="prozorro_auction_dgf_decision_id"]    ${dgfDecisionID}
  Input Text   xpath=//input[@id="prozorro_auction_dgf_decision_date"]  ${dgfDecisionDate}
  ${tender_attempts}=   Convert To String   ${tenderAttempts}
  Select From List By Value   xpath=//select[@id="prozorro_auction_tender_attempts"]    ${tender_attempts}
# Auction Start date
  ${inp_start_date}=   repair_start_date   ${start_date}
  Input Text   xpath=//input[@id="prozorro_auction_auction_period_attributes_should_start_after"]    ${inp_start_date}
# Budget data add
  ${budget_string}      Convert To String    ${budget}
  Input Text   ${locator.value.amount}       ${budget_string}
  Click Element    xpath=//label[@for="prozorro_auction_value_attributes_vat_included"]
  ${step_rate_string}   Convert To String     ${step_rate}
  Input Text   ${locator.minimalStep.amount}  ${step_rate_string}
  ${guarantee_string}   Convert To String     ${guarantee}
  Input Text    ${locator.guaranteeamount}    ${guarantee_string}
#  Items block info
# === Loop Try to select items info ===
  ${item_number}=   substract             ${NUMBER_OF_ITEMS}    1
  ${item_number}=   Convert To Integer    ${item_number}
  : FOR   ${INDEX}  IN RANGE    0    ${NUMBER_OF_ITEMS}
  \   ${items}=         Get From Dictionary   ${ARGUMENTS[1].data}            items
  \   ${item[x]}=                              Get From List               ${items}                 ${INDEX}
  \   ${item_description}=                  Get From Dictionary         ${item[x]}     description
  \   ${item_quantity}=                     Get From Dictionary         ${item[x]}     quantity
  \   ${unit}=                              Get From Dictionary         ${item[x]}     unit
  \   ${unit_code}=                         Get From Dictionary         ${unit}        code
  \   ${unit_name}=                         Get From Dictionary         ${unit}        name
  \   ${classification}=                    Get From Dictionary         ${item[x]}     classification
  \   ${classification_scheme}=             Get From Dictionary         ${classification}    scheme
  \   ${classification_description}=        Get From Dictionary         ${classification}    description
  \   ${classification_id}=                 Get From Dictionary         ${classification}    id
  \   ${deliveryaddress}=                   Get From Dictionary         ${item[x]}           deliveryAddress
  \   ${deliveryaddress_postalcode}=        Get From Dictionary         ${deliveryaddress}   postalCode
  \   ${deliveryaddress_countryname}=       Get From Dictionary         ${deliveryaddress}   countryName
  \   ${deliveryaddress_streetaddress}=     Get From Dictionary         ${deliveryaddress}   streetAddress
  \   ${deliveryaddress_region}=            Get From Dictionary         ${deliveryaddress}   region
  \   ${deliveryaddress_locality}=          Get From Dictionary         ${deliveryaddress}   locality
# Add Item(s)
  \   ${item_descr_field}=   Get Webelements     xpath=//textarea[contains(@id, 'prozorro_auction_items_attributes_') and contains(@id, '_description_ua')]
  \   Input Text    ${item_descr_field[-1]}     ${item_description}
  \   ${item_quantity_field}=   Get Webelements     xpath=//input[contains(@id, 'prozorro_auction_items_attributes') and contains(@id, '_quantity')]
  \   Input Text    ${item_quantity_field[-1]}           ${item_quantity}
  \   ${unit_name_field}=   Get Webelements     xpath=//select[contains(@id, 'prozorro_auction_items_attributes_') and contains(@id, '_unit_code')]
  \   Select From List By Value   ${unit_name_field[-1]}    ${unit_code}
# Selecting classifier
  \   ${classifier_field}=      Get Webelements     xpath=//span[@class="btn btn_editing"]
  \   Click Element     ${classifier_field[-1]}
  \   Sleep     2
  \   Input Text        id=search_classification    ${classification_id}
  \   set_clacifier   ${classification_id}
  \   Click Element     xpath=//span[@class='button btn_adding']
  \   Sleep     2
# Add delivery address
  \   ${delivery_zip_field}=   Get Webelements     ${locator.delivery_zip}
  \   Input Text        ${delivery_zip_field[-1]}      ${deliveryaddress_postalcode}
  \   ${delivery_country_field}=   Get Webelements     ${locator.delivery_country}
  \   Select From List By Value   ${delivery_country_field[-1]}    ${deliveryaddress_countryname}
  \   ${region_name}=   get_region_name   ${deliveryaddress_region}
  \   ${region_name_field}=   Get Webelements     ${locator.delivery_region}
  \   Select From List By Value   ${region_name_field[-1]}    ${region_name}
  \   ${delivery_town_field}=   Get Webelements     ${locator.delivery_town}
  \   Input Text        ${delivery_town_field[-1]}     ${deliveryaddress_locality}
  \   ${delivery_address_field}=   Get Webelements     ${locator.delivery_address}
  \   Input Text        ${delivery_address_field[-1]}  ${deliveryaddress_streetaddress}
  \   Run Keyword If   '${INDEX}' < '${item_number}'   Click Element     ${locator.add_item}
  \   Sleep     3
# Save Auction - publish to CDB
  Click Element                      ${locator.publish}

  Wait Until Page Contains Element     xpath=//div[@class="blue_block top_border"]   60

# Get Ids
  : FOR   ${INDEX}  IN RANGE    1   15
  \   Wait Until Page Contains Element     xpath=//div[@class="blue_block top_border"]
  \   ${id_values}=      Get Webelements     xpath=//div[@class="blue_block top_border"]/div/div
  \   ${uid_val}=   Get Text  ${id_values[3]}
  \   ${TENDER_UAID}=   get_ua_id   ${uid_val}
  \   Exit For Loop If  '${TENDER_UAID}' > '0'
  \   Sleep     30
  \   Reload Page
  [Return]  ${TENDER_UAID}

set_clacifier
  [Arguments]       ${classification_id}
  ${nonzero_num}  ${start_num}=   get_nonzero_num   ${classification_id}
  :FOR   ${INDEX_N}  IN RANGE    ${start_num}    ${nonzero_num}
  \   ${first_code_symbols}=   get_first_symbols   ${classification_id}   ${INDEX_N}
  \   Sleep    3
  \   Click Element     xpath=//label[starts-with(@for, '${first_code_symbols}')]
  \   Sleep     2

Пошук тендера по ідентифікатору
  [Arguments]  @{ARGUMENTS}
  [Documentation]
  ...      ${ARGUMENTS[0]} ==  username
  ...      ${ARGUMENTS[1]} ==  ${TENDER_UAID}
  Switch browser   ${ARGUMENTS[0]}
  Run Keyword If   '${ARGUMENTS[0]}' == 'tabua_Owner'   Go To  ${BROKERS['tabua'].auctionpage}
  Run Keyword If   '${ARGUMENTS[0]}' != 'tabua_Owner'   Go To  ${BROKERS['tabua'].startpage}
  :FOR   ${INDEX_N}  IN RANGE    1    15
  \   Wait Until Page Contains Element     id=q  10
  \   Input Text        id=q   ${ARGUMENTS[1]}
  \   Click Element   xpath=//input[@class="button btn_search"]
  \   Sleep   3
  \   ${auc_on_page}=    Run Keyword And return Status    Wait Until Element Is Visible    xpath=//a[@class="auction_title accordion-title"]    10s
  \   Exit For Loop If    ${auc_on_page}
  \   Sleep   5
  \   Reload Page
  Sleep   3
  ${g_value}=   Get Element Attribute   xpath=//div[contains(@id, "auction_tabs_")]@id
  ${auc_url}=   get_auc_url   ${g_value}
  Go To  ${auc_url}
  Sleep  3


############# Tender info #########
Отримати інформацію із тендера
  [Arguments]  @{ARGUMENTS}
  [Documentation]
  ...      ${ARGUMENTS[0]} ==  username
  ...      ${ARGUMENTS[1]} ==  tender_uaid
  ...      ${ARGUMENTS[2]} ==  field_name
#  Sleep   5
#  Reload Page
#  Sleep   2
  Run Keyword And Return  Отримати інформацію про ${ARGUMENTS[2]}

Отримати тест із поля і показати на сторінці
    [Arguments]   ${field_name}
    ${return_value}=   Get Text  ${locator.${field_name}}
    [Return]  ${return_value}

Отримати текст із поля і показати на сторінці
    [Arguments]   ${field_name}
    ${return_value}=   Get Text  ${locator.view.${field_name}}
    [Return]  ${return_value}

Отримати інформацію про tenderPeriod.endDate
    ${return_value}=    Отримати тест із поля і показати на сторінці  tenderPeriod.endDate
    [Return]    ${return_value}

Отримати інформацію про value.amount
  ${valueAmount}=   Отримати текст із поля і показати на сторінці   value.amount
  ${valueAmount}=   Convert To Number   ${valueAmount.replace(' ','').replace(',','.')}
  [Return]  ${valueAmount}

Отримати інформацію про procurementMethodType
  ${dgf_value}=   Get Element Attribute   xpath=//div[contains(@class, "auction_type auction_type_")]@class
  ${dgf_value}=   change_dgf   ${dgf_value}
  [Return]  ${dgf_value}

Отримати інформацію про minimalStep.amount
  Click Element   xpath=//a[contains(@id,'auction_tab_detail_')]
  Sleep  3
  ${return_value}=   Отримати текст із поля і показати на сторінці   minimalStep.amount
  ${return_value}=    Convert To Number   ${return_value.replace(' ', '').replace(',', '.')}
  Click Element   xpath=//a[contains(@id,'main_tab_detail_')]
  [Return]   ${return_value}

Отримати кількість предметів в тендері
  [Arguments]  @{ARGUMENTS}
  [Documentation]
  ...      ${ARGUMENTS[0]} =  username
  ...      ${ARGUMENTS[1]} =  tender_uaid
  Switch Browser    ${ARGUMENTS[0]}
  Wait Until Page Contains Element    xpath=//li[@class="row item bottom_border"]     20
  ${res}=   Get Text      xpath=//li[@class="row item bottom_border"]
  [return]  ${res}

Отримати інформацію про awards[0].status
  Reload Page
  Sleep     2
  ${award_status} =    Get Text    xpath=//ul[@class="accordion bids_list"]/li/a/div[@class="row"]/div[contains(@class, "bid_status")][0]
  ${correct_status}=    convert_nt_string_to_common_string      ${award_status}
  [Return]    ${correct_status}

Отримати інформацію про awards[1].status
  Reload Page
  Sleep     2
  ${award_status} =    Get Text    xpath=//ul[@class="accordion bids_list"]/li/a/div[@class="row"]/div[contains(@class, "bid_status")][1]
  ${correct_status}=    convert_nt_string_to_common_string      ${award_status}
  [Return]    ${correct_status}


####  Client  #################
Отримати інформацію про title
  ${new_title}  Get Text  css=span.auction_short_title_text
  [return]  ${new_title}

Отримати інформацію про dgfID
  ${return_value}=   Get Text  xpath=//div[@class="small-6 columns"][1]
  [Return]  ${return_value}

Отримати інформацію про description
  ${desc1}=   Get Text  xpath=//div[@class="small-7 columns auction_description"]
  ${desc2}=   Get Text  xpath=//div[@class="auction_attempts"]
  ${desc}=  convert_desc  ${desc1}  ${desc2}
  [Return]  ${desc}

Отримати інформацію про value.valueAddedTaxIncluded
  ${tax}=   Get Text  xpath=//span[@class="amount"][1]
  ${tax}=   Convert To Boolean   ${tax}
  [Return]  ${tax}

Отримати інформацію про auctionID
  ${return_value}=   Get Text  xpath=//div[@class="small-6 columns auction_ua_id"]
  [Return]  ${return_value}

Отримати інформацію про procuringEntity.name
  ${return_value}=   Get Text  xpath=//div[@class="small-10 columns"][1]
  [Return]  ${return_value}

Отримати інформацію із classification.scheme
  ${return_value}=   Get Text  xpath=//div[@class="item_classificator"][1]
  [return]  ${return_value.split(':')[0]}

Отримати інформацію із classification.id
  [Arguments]   @{arguments}
  [Documentation]
  ...           ${ARGUMENTS[0]} == user_role
  ...           ${ARGUMENTS[1]} == auction_id
  ...           ${ARGUMENTS[2]} == field_name
  Run Keyword And Return   Отримати інформацію про ${ARGUMENTS[2]}

Отримати інформацію про items[0].classification.id
  Sleep  5
  Wait Until Page Contains Element     xpath=//div[@class="item_title"]
  ${des}=   GET WEBELEMENTS  xpath=//div[@class="item_classificator"]
  ${_id}=   Get Text  ${des[0]}
  [Return]  ${_id.split(': ')[1].split(' -')[0]}

Отримати інформацію про items[1].classification.id
  Wait Until Page Contains Element     xpath=//div[@class="item_title"]
  ${des}=   GET WEBELEMENTS  xpath=//div[@class="item_classificator"]
  ${_id}=   Get Text  ${des[1]}
  [Return]  ${_id.split(': ')[1].split(' -')[0]}

Отримати інформацію про items[2].classification.id
  Wait Until Page Contains Element     xpath=//div[@class="item_title"]
  ${des}=   GET WEBELEMENTS  xpath=//div[@class="item_classificator"]
  ${_id}=   Get Text  ${des[2]}
  [Return]  ${_id.split(': ')[1].split(' -')[0]}

Переглянути текст із поля і показати на сторінці
  [Arguments]   ${field_name}
  ${return_value}=   Get Text  ${locator.view.${field_name}}
  Sleep  3
  [Return]  ${return_value}

#############   classification.description   #################
Отримати інформацію із classification.description
  [Arguments]   @{arguments}
  [Documentation]
  ...           ${ARGUMENTS[0]} == user_role
  ...           ${ARGUMENTS[1]} == auction_id
  ...           ${ARGUMENTS[2]} == field_name
  Run Keyword And Return   Отримати інформацію про ${ARGUMENTS[2]}

Отримати інформацію про items[0].classification.description
  Sleep  5
  Wait Until Page Contains Element     xpath=//div[@class="item_title"]
  ${des}=   GET WEBELEMENTS  xpath=//div[@class="item_title"]
  ${_id}=   Get Text  ${des[0]}
  [Return]  ${_id.split(':')[-1].strip()}

Отримати інформацію про items[1].classification.description
  Wait Until Page Contains Element     xpath=//div[@class="item_title"]
  ${des}=   GET WEBELEMENTS  xpath=//div[@class="item_title"]
  ${_id}=   Get Text  ${des[1]}
  [Return]  ${_id.split(':')[-1].strip()}

Отримати інформацію про items[2].classification.description
  Wait Until Page Contains Element     xpath=//div[@class="item_title"]
  ${des}=   GET WEBELEMENTS  xpath=//div[@class="item_title"]
  ${_id}=   Get Text  ${des[2]}
  [Return]  ${_id.split(':')[-1].strip()}

Отримати інформацію про items[0].unit.name
  ${units}=     Get Webelements     xpath=//div[@class="small-1 small-offset-1 columns"]
  ${unit_name}=     Get Text    ${units[0]}
  ${unit_name}=  get_select_unit_name  ${unit_name.split(' ')[-1]}
  [Return]  ${unit_name}

Отримати інформацію про items[1].unit.name
  ${units}=     Get Webelements     xpath=//div[@class="small-1 small-offset-1 columns"]
  ${unit_name}=     Get Text    ${units[1]}
  ${unit_name}=  get_select_unit_name  ${unit_name.split(' ')[-1]}
  [Return]  ${unit_name}

Отримати інформацію про items[2].unit.name
  ${units}=     Get Webelements     xpath=//div[@class="small-1 small-offset-1 columns"]
  ${unit_name}=     Get Text    ${units[2]}
  ${unit_name}=  get_select_unit_name  ${unit_name.split(' ')[-1]}
  [Return]  ${unit_name}

Отримати інформацію із unit.code
  [Arguments]   @{arguments}
  [Documentation]
  ...           ${ARGUMENTS[0]} == user_role
  ...           ${ARGUMENTS[1]} == auction_id
  ...           ${ARGUMENTS[2]} == field_name
  Run Keyword And Return   Отримати інформацію про ${ARGUMENTS[2]}

Отримати інформацію про items[0].unit.code
  ${units}=     Get Webelements     xpath=//div[@class="small-1 small-offset-1 columns"]
  ${unit_code}=     Get Text    ${units[0]}
  ${unit_code}=  get_select_unit_code  ${unit_code.split(' ')[-1].strip()}
  [Return]  ${unit_code}

Отримати інформацію про items[1].unit.code
  ${units}=     Get Webelements     xpath=//div[@class="small-1 small-offset-1 columns"]
  ${unit_code}=     Get Text    ${units[1]}
  ${unit_code}=  get_select_unit_code  ${unit_code.split(' ')[-1].strip()}
  [Return]  ${unit_code}

Отримати інформацію про items[2].unit.code
  ${units}=     Get Webelements     xpath=//div[@class="small-1 small-offset-1 columns"]
  ${unit_code}=     Get Text    ${units[2]}
  ${unit_code}=  get_select_unit_code  ${unit_code.split(' ')[-1].strip()}
  [Return]  ${unit_code}

Отримати інформацію із quantity
  [Arguments]   @{arguments}
  [Documentation]
  ...           ${ARGUMENTS[0]} == user_role
  ...           ${ARGUMENTS[1]} == auction_id
  ...           ${ARGUMENTS[2]} == field_name
  Run Keyword And Return   Отримати інформацію про ${ARGUMENTS[2]}

Отримати інформацію про items[0].quantity
  ${units}=     Get Webelements     xpath=//div[@class="small-1 small-offset-1 columns"]
  ${unit_name}=     Get Text    ${units[0]}
  ${unit_name}=  Convert To Integer  ${unit_name.split(' ')[0]}
  [Return]  ${unit_name}

Отримати інформацію про items[1].quantity
  ${units}=     Get Webelements     xpath=//div[@class="small-1 small-offset-1 columns"]
  ${unit_name}=     Get Text    ${units[1]}
  ${unit_name}=  Convert To Integer  ${unit_name.split(' ')[0]}
  [Return]  ${unit_name}

Отримати інформацію про items[2].quantity
  ${units}=     Get Webelements     xpath=//div[@class="small-1 small-offset-1 columns"]
  ${unit_name}=     Get Text    ${units[2]}
  ${unit_name}=  Convert To Integer  ${unit_name.split(' ')[0]}
  [Return]  ${unit_name}

Отримати інформацію про value.currency
    ${return_value}=   Get Text  xpath=//span[@class="currency"]
    ${return_value}=   get_select_unit_name      ${return_value}
    [Return]  ${return_value}

Додати предмет закупівлі
  [Arguments]   @{ARGUMENTS}
  [Documentation]
  ...     ${ARGUMENTS[0]} == username
  ...     ${ARGUMENTS[1]} == tender_uaid
  ...     ${ARGUMENTS[2]} == item_info
  Log To Console    user - ${ARGUMENTS[1]}

Видалити предмет закупівлі
  [Arguments]   @{ARGUMENTS}
  [Documentation]
  ...     ${ARGUMENTS[0]} == username
  ...     ${ARGUMENTS[1]} == tender_uaid
  ...     ${ARGUMENTS[2]} == item_id
  Log To Console    user - ${ARGUMENTS[0]}

Отримати інформацію про eligibilityCriteria
# “Incorrect requirement, see the decision of DGF from 21.01.2017
  [Return]  ${BROKERS['tabua'].eligibilitycriteria}

######### Item info #########
Отримати інформацію із предмету
  [Arguments]  @{ARGUMENTS}
  [Documentation]
  ...      ${ARGUMENTS[0]} ==  username
  ...      ${ARGUMENTS[1]} ==  tender_uaid
  ...      ${ARGUMENTS[2]} ==  item_id
  ...      ${ARGUMENTS[3]} ==  field_name
  Run Keyword And Return  Отримати інформацію із ${ARGUMENTS[3]}

Отримати інформацію про items[0].description
# Відображення опису номенклатур тендера
  ${description_raw}=   Переглянути текст із поля і показати на сторінці   items[0].description
  ${description_1}=     Get Substring     ${description_raw}  0   11
  ${description_2}=     convert_nt_string_to_common_string  ${description_raw.split(': ')[-1]}
  ${description}=       Catenate  ${description_1}  ${description_2}
  [Return]  ${description}

Отримати інформацію із unit.name
  ${unit_name}=   Get Text      xpath=//div[contains(., '${item_id}')]//span[@class="unit ng-binding"]
  [Return]  ${unit_name}


Отримати інформацію із description
  ${descriptions}=   GET WEBELEMENTS  xpath=//div[@class="item_title"]
  ${description0}=  GET TEXT  ${descriptions[0]}
  ${description1}=  GET TEXT  ${descriptions[1]}
  ${description2}=  GET TEXT  ${descriptions[2]}
  @{ITEMS}  CREATE LIST  ${description0}  ${description1}  ${description2}
  ${description}=   get_next_description  @{ITEMS}
  [Return]  ${description}

Отримати інформацію про dgfDecisionDate
  ${return_value}=   Get Webelements  xpath=//div[@class="small-6 columns"]
  ${return_value}=   Get Text  ${return_value[1]}
  [Return]  ${return_value.split(' ')[-1]}

Отримати інформацію про dgfDecisionID
  ${return_value}=   Get Webelements  xpath=//div[@class="small-6 columns"]
  ${return_value}=   Get Text  ${return_value[1]}
  [Return]      ${return_value.split(' ')[0]}

Отримати інформацію про tenderAttempts
  ${return_value}=   Get Text   xpath=//div[@class="tabs-panel is-active main_tab_detail"]/div/div/span
  ${return_value}=   convert_string_to_integer   ${return_value}
  [Return]      ${return_value}

 ######### Changes #########

Внести зміни в тендер
  [Arguments]  ${user_name}  ${tender_id}  ${field}  ${value}
  tabua.Пошук тендера по ідентифікатору  ${user_name}  ${tender_id}
  ${at_auc_page}=    Run Keyword And return Status    Wait Until Element Is Visible    xpath=//a[text()[contains(.,'Змінити')]]    10s
  Run Keyword If	${at_auc_page}	Перейти на сторінку зміни параметрів аукціону   ${field}	${value}
  Run Keyword If	${at_auc_page}!=True	Перевірити доступність зміни і змінити лот    ${field}	${value}


Перейти на сторінку зміни параметрів аукціону
  [Arguments]  ${field}    ${value}
  Click Element   xpath=//a[text()[contains(.,'Змінити')]]
  Wait Until Element Is Visible    xpath=//div[text()[contains(.,'Редагування аукціону')]]    10
  Перевірити доступність зміни і змінити лот    ${field}	${value}

Перевірити доступність зміни і змінити лот
  [Arguments]  ${field}	 ${value}
  ${avail_change}=    Run Keyword And return Status    Wait Until Element Is Visible	${locator.title}	10s
  Run Keyword If    ${avail_change}!=True    Додати документ
  Sleep  5
  Run Keyword	Змінити ${field}	${value}
  Click Element     xpath=//input[@name="commit"]
  Sleep  10
  Reload Page
  Sleep  3

Додати документ
  ${file_path}  ${file_name}  ${file_content}=  create_fake_doc
  ${add_doc_button}=   Get Webelements     xpath=//a[@class="button btn_white documents_add add_fields"]
  Click Element       ${add_doc_button[0]}
  Sleep   1
  Choose File       xpath=//input[@type="file"]        ${file_path}

Змінити value.amount
    [Arguments]  ${value}
    Input text	${locator.value.amount}	'${value}'

Змінити minimalStep.amount
    [Arguments]  ${value}
    Input text	${locator.minimalStep.amount}	'${value}'

Змінити title
  [Arguments]  ${value}
  Input Text   ${locator.title}          ${value}

Змінити description
  [Arguments]  ${value}
  Input Text   ${locator.description}          ${value}

Змінити procuringEntity.name
  [Arguments]  ${value}
  Input text	 xpath=//label[@for="prozorro_auction_procurement_method_type_dgf_financial_assets"] 	${value}

Змінити tenderPeriod.startDate
  [Arguments]  ${value}
  ${inp_start_date}=   repair_start_date   ${value}
  Input Text   xpath=//input[@id="prozorro_auction_auction_period_attributes_should_start_after"]    ${inp_start_date}

Змінити eligibilityCriteria
  [Arguments]  ${value}
# “Incorrect requirement, see the decision of DGF from 21.01.2017
  Input text	css=input[tid='eligibilityCriteria']	${value}

Змінити guarantee
    [Arguments]  ${value}
    Input text	${locator.guaranteeamount}	${value}

Змінити dgfDecisionDate
    [Arguments]  ${value}
    Input Text   xpath=//input[@id="prozorro_auction_dgf_decision_date"]  ${value}

Змінити dgfID
    [Arguments]  ${value}
    Input Text   ${locator.dgfid}    ${value}

Змінити dgfDecisionID
    [Arguments]  ${value}
    Input Text   xpath=//input[@id="prozorro_auction_dgf_decision_id"]    ${value}

Змінити tenderAttempts
  [Arguments]  ${value}
  ${tender_attempts}=   Convert To String   ${value}
  Select From List By Value   xpath=//select[@id="prozorro_auction_tender_attempts"]    ${tender_attempts}

Завантажити ілюстрацію
  [Arguments]  ${user_name}  ${tender_id}  ${filepath}
  ${at_auc_page}=    Run Keyword And return Status    Wait Until Element Is Visible	xpath=//a[text()[contains(.,'Змінити')]]	10s
  Run Keyword If	${at_auc_page}	Click Element   xpath=//a[text()[contains(.,'Змінити')]]
  Wait Until Element Is Visible	    xpath=//div[text()[contains(.,'Редагування аукціону')]]    10
  ${add_doc_button}=   Get Webelements     xpath=//a[@class="button btn_white documents_add add_fields"]
  Click Element       ${add_doc_button[-1]}
  Choose File       xpath=//input[@type="file"]        ${file_path}
  Click Element     xpath=//input[@name="commit"]
  Sleep  5

Завантажити документ в тендер з типом
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${doc_type}
  ${at_auc_page}=    Run Keyword And return Status    Wait Until Element Is Visible	xpath=//a[text()[contains(.,'Змінити')]]	10s
  Run Keyword If	${at_auc_page}	Click Element   xpath=//a[text()[contains(.,'Змінити')]]
  Wait Until Element Is Visible  	xpath=//div[text()[contains(.,'Редагування аукціону')]]    10
  ${add_doc_button}=   Get Webelements     xpath=//a[@class="button btn_white documents_add add_fields"]
  Click Element       ${add_doc_button[-2]}
  Choose File       xpath=//input[@type="file"]        ${file_path}
  Click Element     xpath=//input[@name="commit"]
  Sleep  5

Завантажити документ
  [Arguments]  ${user_name}  ${filepath}  ${tender_id}=${None}
  ${at_auc_page}=    Run Keyword And return Status    Wait Until Element Is Visible	xpath=//a[text()[contains(.,'Змінити')]]	10s
  Run Keyword If	${at_auc_page}	Click Element   xpath=//a[text()[contains(.,'Змінити')]]
  Wait Until Element Is Visible	    xpath=//div[text()[contains(.,'Редагування аукціону')]]    10
  ${add_doc_button}=   Get Webelements     xpath=//a[@class="button btn_white documents_add add_fields"]
  Click Element       ${add_doc_button[0]}
  Choose File       xpath=//input[@type="file"]        ${filepath}
  Click Element     xpath=//input[@name="commit"]
  Sleep  5

Додати Virtual Data Room
  [Arguments]  ${username}  ${tender_uaid}  ${vdr_url}  ${title}=Sample Virtual Data Room
  ${at_auc_page}=   Run Keyword And return Status    Wait Until Element Is Visible	 xpath=//a[text()[contains(.,'Змінити')]]	10s
  Run Keyword If	${at_auc_page}	Click Element   xpath=//a[text()[contains(.,'Змінити')]]
  Wait Until Page Contains Element      xpath=//textarea[contains(@id, 'prozorro_auction_documents_attributes_')]    10
  Input Text         xpath=//textarea[contains(@id, 'prozorro_auction_documents_attributes_')]          ${vdr_url}
  Sleep  5
  Click Element     xpath=//input[@name="commit"]
  Sleep  5

Додати публічний паспорт активу
  [Arguments]  ${username}  ${tender_uaid}  ${certificate_url}  ${title}=Public Asset Certificate
  ${at_auc_page}=    Run Keyword And return Status    Wait Until Element Is Visible	xpath=//a[text()[contains(.,'Змінити')]]	10s
  Run Keyword If	${at_auc_page}	Click Element   xpath=//a[text()[contains(.,'Змінити')]]
  Wait Until Page Contains Element      xpath=//textarea[contains(@id, 'prozorro_auction_documents_attributes_')]    10
  Input Text         xpath=//textarea[contains(@id, 'prozorro_auction_documents_attributes_')]          ${certificate_url}
  Sleep  5
  Click Element     xpath=//input[@name="commit"]
  Sleep  5

Додати офлайн документ
  [Arguments]  ${user_name}  ${tender_id}  ${accessDetails}
  ${at_auc_page}=    Run Keyword And return Status    Wait Until Element Is Visible	xpath=//a[text()[contains(.,'Змінити')]]	10s
  Run Keyword If	${at_auc_page}	Click Element   xpath=//a[text()[contains(.,'Змінити')]]
  Wait Until Page Contains Element      xpath=//textarea[contains(@id, 'prozorro_auction_documents_attributes_')]    10
  Input Text         xpath=//textarea[contains(@id, 'prozorro_auction_documents_attributes_')]          ${accessDetails}
  Sleep  5
  Click Element     xpath=//input[@name="commit"]
  Sleep  5

#################### Questions ######################

Задати запитання на тендер
  [Arguments]  ${user_name}  ${tender_id}  ${question_data}
  Wait Until Element Is Visible			xpath=//div[@class="columns blue_block questions"]//span[@class="button your_organization_need_verified to_modal"]	 5
  Click Element							xpath=//div[@class="columns blue_block questions"]//span[@class="button your_organization_need_verified to_modal"]
  Wait Until Element Is Visible			id=prozorro_question_title   5
  Input Text							id=prozorro_question_title	${question_data.data.title}
  Input Text							id=prozorro_question_description	${question_data.data.description}
  Click Element							xpath=//input[@name="commit"]
  Check if question on page by id       ${question_data.data.title}

Check if question on page by id
  [Arguments]  ${q_id}
   : FOR   ${INDEX}  IN RANGE    1   15
  \   Log To Console   .   no_newline=true
  \   ${text}=   Get Matching Xpath Count   xpath=//ul[@class="questions_list"]//div[@class="question_title" and contains(text(),"${q_id}")]
  \   Exit For Loop If  '${text}' > '0'
  \   Sleep     10
  \   Reload Page

Задати запитання на предмет
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${question_data}
  tabua.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Wait Until Element Is Visible			xpath=//div[@class="columns blue_block questions"]//span[@class="button your_organization_need_verified to_modal"]	 20
  Sleep    2
  Click Element							xpath=//div[@class="columns blue_block questions"]//span[@class="button your_organization_need_verified to_modal"]
  Wait Until Element Is Visible			id=prozorro_question_title   20
  Input Text							id=prozorro_question_title	                                    ${question_data.data.title}
  Click Element							xpath=//span[@class="select2-selection__arrow"]
  Sleep    2
  Input Text							xpath=//input[@class="select2-search__field"]	                ${item_id}
  Sleep    3
  Click Element                         xpath=//li[contains(@id, "select2-prozorro_question_item_id-result-")]
  Sleep    1
  Input Text							id=prozorro_question_description	                ${question_data.data.description}
  Sleep    2
  Click Element							xpath=//input[@name="commit"]
  Check if question on page by id       ${question_data.data.title}

Отримати інформацію із запитання
  [Arguments]  ${username}  ${tender_uaid}  ${questions_id}  ${field_name}
  Check if question on page by id       ${questions_id}
  ${titles} =    Get Webelements     xpath=//ul[@class="questions_list"]/li/div[@class="question_title"]
  ${descriptions} =    Get Webelements     xpath=//ul[@class="questions_list"]/li/div[@class="question_text"]
  ${size} =    Get Length	${titles}
  ${title} =	Set Variable	${EMPTY}
  ${descr} =    Set Variable	${EMPTY}
  : FOR    ${i}    IN RANGE    0    ${size}+1
  \    ${title} =    Get Text    ${titles[${i}]}
  \    ${descr} =    Get Text    ${descriptions[${i}]}
  \    Exit For Loop If    "${questions_id}" in "${title}"
  ${return_value}=      Run Keyword If   '${field_name}' == 'title'
    ...     Set Variable    ${title}
    ...     ELSE IF  '${field_name}' == 'answer'     Get Text   xpath=//div[@class='zk-question' and .//p[contains(text(), '${question_id}')]]//span[@class='qa_answer']
    ...     ELSE    Get Text   xpath=//div[@class='zk-question' and .//p[contains(text(), '${question_id}')]]//div[contains(@class, 'qa_message_description')]
  [Return]     ${return_value}

Check if question on page by num
  [Arguments]  ${num}
  : FOR   ${INDEX}  IN RANGE    1   15
  \   ${question_list}=    Get Webelements    xpath=//ul[@class="questions_list"]/li/div[@class="question_title"]
  \   ${q_lenght}=    Get Length	${question_list}
  \   Sleep     10
  \   Exit For Loop If  '${q_lenght}' > '${num}'
  \   Reload Page
  \   Sleep     10

Отримати інформацію про questions[0].title
  Check if question on page by num    0
  ${q_title_els}=    Get Webelements     xpath=//ul[@class="questions_list"]/li/div[@class="question_title"]
  ${q_title}=   Get Text  ${q_title_els[0]}
  [Return]    ${q_title}

Отримати інформацію про questions[1].title
  Check if question on page by num    1
  ${q_title_els}=    Get Webelements     xpath=//ul[@class="questions_list"]/li/div[@class="question_title"]
  ${q_title}=   Get Text  ${q_title_els[1]}
  [Return]    ${q_title}

Отримати інформацію про questions[2].title
  Check if question on page by num    2
  ${q_title_els}=    Get Webelements     xpath=//ul[@class="questions_list"]/li/div[@class="question_title"]
  ${q_title}=   Get Text  ${q_title_els[2]}
  [Return]    ${q_title}

Отримати інформацію про questions[3].title
  Check if question on page by num    3
  ${q_title_els}=    Get Webelements     xpath=//ul[@class="questions_list"]/li/div[@class="question_title"]
  ${q_title}=   Get Text  ${q_title_els[3]}
  [Return]    ${q_title}

Отримати інформацію про questions[0].description
  Check if question on page by num    0
  ${q_descr_els}=    Get Webelements     xpath=//ul[@class="questions_list"]/li/div[@class="question_text"]
  ${q_descr}=   Get Text  ${q_descr_els[0]}
  [Return]    ${q_descr}

Отримати інформацію про questions[1].description
  Check if question on page by num    1
  ${q_descr_els}=    Get Webelements     xpath=//ul[@class="questions_list"]/li/div[@class="question_text"]
  ${q_descr}=   Get Text  ${q_descr_els[1]}
  [Return]    ${q_descr}

Отримати інформацію про questions[2].description
  Check if question on page by num    2
  ${q_descr_els}=    Get Webelements     xpath=//ul[@class="questions_list"]/li/div[@class="question_text"]
  ${q_descr}=   Get Text  ${q_descr_els[2]}
  [Return]    ${q_descr}

Отримати інформацію про questions[3].description
  Check if question on page by num    3
  ${q_descr_els}=    Get Webelements     xpath=//ul[@class="questions_list"]/li/div[@class="question_text"]
  ${q_descr}=   Get Text  ${q_descr_els[3]}
  [Return]    ${q_descr}

Отримати інформацію про questions[0].answer
  Check if question on page by num    0
  ${q_answ_els}=    Get Webelements     xpath=//div[@class="question_answer"]/div
  ${q_answ}=   Get Text  ${q_answ_els[0]}
  [Return]  ${q_answ}

Отримати інформацію про questions[1].answer
  Check if question on page by num    1
  ${q_answ_els}=    Get Webelements     xpath=//div[@class="question_answer"]/div
  ${q_answ}=   Get Text  ${q_answ_els[1]}
  [Return]  ${q_answ}

Отримати інформацію про questions[2].answer
  Check if question on page by num    2
  ${q_answ_els}=    Get Webelements     xpath=//div[@class="question_answer"]/div
  ${q_answ}=   Get Text  ${q_answ_els[2]}
  [Return]  ${q_answ}

Отримати інформацію про questions[3].answer
  Check if question on page by num    3
  ${q_answ_els}=    Get Webelements     xpath=//div[@class="question_answer"]/div
  ${q_answ}=   Get Text  ${q_answ_els[3]}
  [Return]  ${q_answ}

Відповісти на запитання
  [Arguments]  ${user_name}  ${tender_id}  ${answer_data}  ${question_id}
  Check if question on page by id       ${question_id}
  ${titles} =           Get Webelements     xpath=//ul[@class="questions_list"]/li/div[@class="question_title"]
  ${answer_buttons} =   Get Webelements     xpath=//span[text()[contains(.,'Дати відповідь')]]
  ${t_size} =	Get Length	${titles}
  ${answ_size} =	Get Matching Xpath Count	xpath=//ul[@class="questions_list"]/li/div[@class="question_answer"]/div
  ${title} =	Set Variable	${EMPTY}
  : FOR    ${i}    IN RANGE    0    ${t_size}+1
  \    ${title} =	Get Text   ${titles[${i}]}
  \    Exit For Loop If    "${question_id}" in "${title}"
  ${index}=    Evaluate    ${i} - ${answ_size}
  Click Button    ${answer_buttons[${index}]}
  Wait Until Element Is Visible	   xpath=//textarea[@id='prozorro_question_answer']
  Input Text	xpath=//textarea[@id='prozorro_question_answer']	${answer_data.data.answer}
  Click Button	xpath=//input[@name="commit"]
  Sleep     20
  Reload Page

#################### Bids #########################

Подати цінову пропозицію
  [Arguments]  @{ARGUMENTS}
  [Documentation]
  ...      ${ARGUMENTS[0]} == username
  ...      ${ARGUMENTS[1]} == tender_uaid
  ...      ${ARGUMENTS[2]} == ${test_bid_data}
  ${amount}=    Get From Dictionary     ${ARGUMENTS[2].data.value}    amount
  Wait Until Element Is Visible			xpath=//div[@class="auction_buttons"]/span[@class="button your_organization_need_verified to_modal"]	20
  Sleep    2
  Click Element     xpath=//div[@class="auction_buttons"]/span[@class="button your_organization_need_verified to_modal"]
  ${amount_bid}=    Convert To Integer                 ${amount}
  Sleep     3
  Clear Element Text  xpath=//input[@id="prozorro_bid_value_attributes_amount"]
  Input Text          xpath=//input[@id="prozorro_bid_value_attributes_amount"]    ${amount_bid}
  ${confirm_webelements}=    Get Webelements     xpath=//div[@class="form_block confirm_rules"]
  Run Keyword If    '${ARGUMENTS[2].data.qualified}'== 'True'    Click Element    ${confirm_webelements[0]}
  Sleep     1
  Run Keyword If    '${ARGUMENTS[2].data.qualified}'== 'True'    Click Element    ${confirm_webelements[1]}
  Sleep     5
  Click Element       xpath=//input[@name="commit"]
  Sleep     5
  Reload Page
  :FOR   ${INDEX_N}  IN RANGE    1    2
  \   ${button_change}=    Run Keyword And return Status    Wait Until Element Is Visible  	xpath=//span[@class="button to_modal"]	  10s
  \   Exit For Loop If    ${button_change}
  \   Sleep   5
  \   Reload Page
  Wait Until Element Is Visible	      xpath=//span[@class="button to_modal"]	  10s
  ${result}=    Set Variable    'Вашу пропозицію було прийнято'
  [Return]     ${result}

Завантажити фінансову ліцензію
  [Arguments]  ${user_name}  ${tender_id}  ${financial_license_path}
  tabua.Завантажити документ в ставку    ${user_name}    ${tender_id}    ${financial_license_path}

Змінити документ в ставці
  [Arguments]  ${user_name}  ${tender_id}  ${filepath}  ${bidid}
  tabua.Завантажити документ в ставку    ${user_name}    ${tender_id}    ${filepath}

Завантажити документ в ставку
  [Arguments]  ${user_name}  ${tender_id}  ${financial_license_path}
  Click Element   xpath=//span[@class="button to_modal"]
  Wait Until Element Is Visible  	xpath=//a[@class="button btn_white documents_add add_fields"]	10s
  Click Element   xpath=//a[@class="button btn_white documents_add add_fields"]
  Choose File       xpath=//input[@type="file"]        ${financial_license_path}
  Click Element     xpath=//input[@name="commit"]
  Sleep  3
  tabua.Пошук тендера по ідентифікатору    ${user_name}  ${tender_id}

Змінити цінову пропозицію
  [Arguments]  ${user_name}  ${tender_id}  ${name}  ${amount_bid}
  ${amount_bid}=   Convert To String    ${amount_bid}
  Click Element   xpath=//span[@class="button to_modal"]
  Wait Until Element Is Visible	  xpath=//a[@class="button btn_white documents_add add_fields"]	  10s
  Clear Element Text  xpath=//input[@id="prozorro_bid_value_attributes_amount"]
  Input Text          xpath=//input[@id="prozorro_bid_value_attributes_amount"]    ${amount_bid}
  Click Element       xpath=//input[@name="commit"]
  Sleep     3
  Reload Page
  tabua.Пошук тендера по ідентифікатору    ${user_name}  ${tender_id}

Отримати інформацію із пропозиції
  [Arguments]  ${user_name}  ${tender_id}  ${field}
  ${dollar}= 	Get Text			xpath=//div[@class="your_bid_amount"]/span
  ${cent}= 	    Get Text			xpath=//div[@class="your_bid_amount"]/span/span
  ${result}=    convert_to_price    ${dollar}    ${cent}
  [return]  ${result}


######### Document Viewer ###########
Отримати документ
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}
  Sleep  5
  Wait Until Page Contains Element    xpath=//div[@class="document_link"]/a[contains(text(), '${doc_id}')]     20
  ${file_name}=   Get Text   xpath=//div[@class="document_link"]/a[contains(text(), '${doc_id}')]
  Sleep  5
  ${url}=   Get Element Attribute   xpath=//a[contains(text(), '${doc_id}')]@href
  download_file   ${url}  ${file_name}  ${OUTPUT_DIR}
  [Return]  ${file_name}

Отримати кількість документів в тендері
  [Arguments]   @{ARGUMENTS}
  Click Element   xpath=//a[text()[contains(.,'Документи')]]
  ${number_of_documents}=  Get Matching Xpath Count  //div[@class="document_description"]
  [return]  ${number_of_documents}

Отримати інформацію із документа по індексу
  [Arguments]  ${username}  ${tender_uaid}  ${document_index}  ${field}
  ${doc_value}=  Get Element Attribute  xpath=//li[contains(@class, "document_type_")][${document_index + 1}]@class
  ${doc_value}=  convert_tabua_string_to_common_string  ${doc_value}
  [return]  ${doc_value}

Отримати інформацію із документа
  [Arguments]  @{ARGUMENTS}
  [Documentation]
  ...       ${ARGUMENTS[0]} == username
  ...       ${ARGUMENTS[1]} == auction_uaid
  ...       ${ARGUMENTS[2]} == doc_id
  ...       ${ARGUMENTS[3]} == field
  Sleep     2
  Run Keyword And Return If    '${ARGUMENTS[3]}' == 'title'    Get Text   xpath=//a[contains(text(), '${ARGUMENTS[2]}')]
  [Return]

Отримати інформацію про status
  [Arguments]  @{ARGUMENTS}
  [Documentation]
  ...      ${ARGUMENTS[0]} ==  username
  ...      ${ARGUMENTS[1]} ==  tenderId
  tabua.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}   ${ARGUMENTS[1]}
  ${return_value}=  Get Text  xpath=//div[@class='auction_title']/div/div[2]/span
  ${return_value}=  convert_tabua_string_to_common_string  ${return_value}
  [return]  ${return_value}

Отримати посилання на аукціон для глядача
  [Arguments]  @{ARGUMENTS}
  [Documentation]
  ...      ${ARGUMENTS[0]} ==  username
  ...      ${ARGUMENTS[1]} ==  tenderId
  tabua.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}   ${ARGUMENTS[1]}
  Sleep  3
  Wait Until Page Contains Element    xpath=//div[@class="small-6 columns auction_prozorro_id"]     20
  ${pro_id}=  Get Text    xpath=//div[@class="small-6 columns auction_prozorro_id"]
  ${url}=  Set Variable  https://auction-sandbox.ea.openprocurement.org/auctions/${pro_id}
  [Return]   ${url}

Отримати посилання на аукціон для учасника
  [Arguments]  @{ARGUMENTS}
  [Documentation]
  ...      ${ARGUMENTS[0]} ==  username
  ...      ${ARGUMENTS[1]} ==  tenderId
  tabua.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}   ${ARGUMENTS[1]}
  Sleep  30
  Wait Until Page Contains Element    xpath=//div[@class="small-6 columns auction_prozorro_id"]     20
  ${pro_id}=  Get Text    xpath=//div[@class="small-6 columns auction_prozorro_id"]
  ${url}=  Set Variable  https://auction-sandbox.ea.openprocurement.org/auctions/${pro_id}
  [Return]   ${url}

Завантажити протокол аукціону в авард
  [Arguments]   ${user_name}   ${tender_uaid}   ${auction_protocol_path}   ${award_index}
  Sleep   120
  Зайти в розділ кваліфікація
  ${drop_id}=  Catenate   SEPARATOR=   ${CUEX_LOT_ID}   _pending.verification
  ${action_id}=   Catenate   SEPARATOR=   ${CUEX_LOT_ID}   _uploadprotocol
  Wait Until Keyword Succeeds   5 x   10 s   Run Keywords
  ...   Reload Page
  ...   AND   Клацнути по випадаючому списку  ${drop_id}
  ...   AND   Element Should Be Visible   id=${action_id}
  Виконати дію   ${action_id}
  Wait Until Element Is Visible   id=fileInput1
  Приєднати документ   id=fileInput1   ${auction_protocol_path}
  Sleep    2
  Click Element   xpath=//input[@type="submit"]
  Wait Until Page Contains   Протокол успішно завантажений. Для переходу до іншого етапу - підтвердіть протокол   10
  Перевірити та сховати повідомлення
