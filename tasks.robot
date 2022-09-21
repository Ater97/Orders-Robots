*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables
Library            RPA.Archive
Library            RPA.FileSystem
Library            RPA.Dialogs
Library            RPA.Robocorp.Vault



*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${user_Url}=     Ask for user Input
    Open the robot order website
    ${orders}=    Get orders    ${user_Url}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close the browser

*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=        ${OUTPUT_DIR}${/}output/

*** Keywords ***
Ask for user Input
    Add heading     Type Url to download file
    Add text input    url    
    ${user_Url}=    Run dialog
    RETURN     ${user_Url.url}

Open the robot order website
     ${secret}=    Get Secret    robotUrl
     Open Available Browser   ${secret}[url] 
     #https://robotsparebinindustries.com/#/robot-order

Get orders
    [Arguments]    ${user_Url}
    Download    ${user_Url}    overwrite=True 
    #https://robotsparebinindustries.com/orders.csv
    ${orders}=    Read table from CSV     orders.csv    header=True
    RETURN     ${orders}
    
Close the annoying modal
    Click Button    Yep
Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    #Select Radio Button    group_name    value
    Click Button    id-body-${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input   ${row}[Legs]
    Input Text    address      ${row}[Address]
Preview the robot
    Click Button    preview 


Submit the order

    ${element_exists}=    Check if order was submited
    WHILE    ${element_exists} 
        Click Button    order 
        ${element_exists}=    Check if order was submited
    END
    

Check if order was submited
    ${element_exists}=    Is Element Visible    id:receipt
    IF    ${element_exists} 
        RETURN     False
    ELSE
        RETURN     True
    END

    #Wait Until Keyword Succeeds
    #...    3x
    #...    9.5 sec
    #...    Wait Until Page Contains
    #...    ORDER ANOTHER ROBOT
    #...    0.5s
    

    #${element_exists}=    Get Element States    ${selector}    then    bool(value & attached)
    #Wait Until Keyword Succeeds    3x    0.5 sec    Submit the order
    #Wait Until Page Contains    ORDER ANOTHER ROBOT

Store the receipt as a PDF file 
    [Arguments]     ${Order number}
    TRY
        Wait Until Element Is Visible    id:receipt
    EXCEPT
        Click Button    order 
        Wait Until Element Is Visible    id:receipt
    END
    ${pdf}=   Get Element Attribute    id:receipt   outerHTML
    Html To Pdf    ${pdf}    ${OUTPUT_DIR}${/}output/${Order number}.pdf
    RETURN     ${OUTPUT_DIR}${/}output/${Order number}.pdf
    

Take a screenshot of the robot 
    [Arguments]     ${Order number}
    ${screenshot}=     Screenshot    id:receipt    ${OUTPUT_DIR}${/}output/${Order number}.png
    RETURN     ${OUTPUT_DIR}${/}output/${Order number}.png

Embed the robot screenshot to the receipt PDF file    
    [Arguments]     ${screenshot}    ${pdf}
    #Open Pdf    ${pdf}
    ${files}=    Create List
    ...    ${screenshot}    
    ...    ${pdf}
    Add Files To Pdf    ${files}    ${pdf}

Go to order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}output//PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}

Close the browser
    Close Browser