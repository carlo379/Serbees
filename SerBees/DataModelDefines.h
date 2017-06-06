//  DataModelDefines.h
//  SerBees

#ifndef CAPA_Mfg_Tool_DataModelDefines_h
#define CAPA_Mfg_Tool_DataModelDefines_h

// CREDENTIALS
#define FULL_NAME @"fullNameTF"
#define EMAIL @"emailTF"
#define PASSWORD @"passwordTF"
#define USER_ID @"userID"
#define QUESTION1 @"question1TF"
#define QUESTION2 @"question2TF"
#define ANSWER1 @"answer1TF"
#define ANSWER2 @"answer2TF"
#define LOGGED_EMAIL @"loggedEmail"
#define LOGGED_NAME @"loggedName"
#define INITIAL_USE @"initialUse"

// SERVICE
#define ADDRESS1 @"address1TF"
#define ADDRESS2 @"address2TF"
#define CONTACT @"contactTF"
#define CREATE_DATE @"createDateTF"
#define SERVICE_EMAIL @"emailTF"
#define PHONE @"phoneTF"
#define SERVICE_DESC @"serviceDescTF"
#define SERVICE_NAME @"serviceNameTF"
#define TAGS @"tagsTF"

// CELLS
#define EVENT_CELL_ID @"EventCellID"
#define SECTIONS_CELL_ID @"SectionCellID"
#define PHOTO_CELL_ID @"PhotoCellID"

// PHOTOS
#define IMAGE_PATH @"imagePath"
#define IMAGE_URL @"imageURL"
#define TITLE @"title"
#define SUBTITLE @"subtitle"
#define IMAGE_DATA @"imageData"
#define THUMBNAIL @"thumbnail"
#define PHOTO_ID @"photoID"
#define SIGN_MOVIE_NAME @"signMovie.mp4"
#define SIGN_PHOTO_NAME @"signPhoto.png"

// TAGS
#define EMAIL_TAG 1001
#define PASSWORD_TAG 1002
#define ADD_BT_TAG 1001             //Tag used to identify the Button on UICollection Cell used as a button for adding other photos
#define CELL_WITH_BT_TAG 1002       //Tag used to identify the Cell used as a Button to add more images

// COLOR
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#endif
