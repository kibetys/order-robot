*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Set up Browser
    Download the Excel file
    Make orders from Excel file
    Create ZIP package from PDF files


*** Keywords ***
Set up Browser
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window
    Close the annoying modal

Download the Excel file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Make orders from Excel file
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Fill the from    ${order}
        Preview robot
        Wait Until Keyword Succeeds    5x    1 sec    Send order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another robot
    END

Get orders
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Close the annoying modal
    Wait Until Element Is Visible    class:modal
    Click Button    OK

Fill the from
    [Arguments]    ${row}
    Select From List By Index    id:head    ${row}[Head]
    Click Element    id-body-${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Preview robot
    Click Button    Preview

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${file_path}=    Set Variable    ${OUTPUT_DIR}${/}screenshots${/}preview-${order_number}.png
    Screenshot    id:robot-preview-image    ${file_path}
    RETURN    ${file_path}

Send order
    Click Button    Order
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${order_receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${file_path}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}receipt-${order_number}.pdf
    Html To Pdf    ${order_receipt}    ${file_path}
    RETURN    ${file_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}
    Add Files To PDF    ${files}    ${pdf}
    Close Pdf

Order another robot
    Click Button    Order another robot
    Close the annoying modal

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}/receipts${/}
    ...    ${zip_file_name}
