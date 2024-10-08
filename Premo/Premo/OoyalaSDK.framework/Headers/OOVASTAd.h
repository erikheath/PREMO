/**
 * @class      OOVASTAd OOVASTAd.h "OOVASTAd.h"
 * @brief      OOVASTAd
 * @details    OOVASTAd.h in OoyalaSDK
 * @date       12/8/11
 * @copyright Copyright (c) 2015 Ooyala, Inc. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "OOTBXML.h"
#import "OOVASTAdData.h"

@interface OOVASTAd : NSObject {
@protected
OOVASTAdData *_adData;
}

@property(readonly, nonatomic) NSString *adID;                   /**< the ID of the Ad */
@property(readonly, nonatomic) NSString *system;                 /**< the System */
@property(readonly, nonatomic) NSString *systemVersion;          /**< the System Version */
@property(readonly, nonatomic) NSString *title;                  /**< the title of the Ad */
@property(readonly, nonatomic) NSString *adDescription;            /**< the description of the Ad */
@property(readonly, nonatomic) NSMutableArray *surveyURLs;       /**< the survey URLs of the Ad */
@property(readonly, nonatomic) NSMutableArray *errorURLs;        /**< the error URLs of the Ad */
@property(readonly, nonatomic) NSMutableArray *impressionURLs;   /**< the impression URLs of the Ad */
@property(readonly, nonatomic) NSMutableArray *sequence;         /**< the ordered sequence of the Ad (NSMutableArray of OOVASTSequenceItem) */
@property(readonly, nonatomic) NSDictionary *extensions;         /**< the extensions of the Ad */

@property(readwrite, nonatomic) float adSequence;                /**< the sequence of the Ad */
-(instancetype) init __attribute__((unavailable("init not available")));

/** @internal
 * Initialize a OOVASTAd using the specified xml (subclasses should override this)
 * @param[in] xml the OOTBXMLElement containing the xml to use to initialize this OOVASTAd
 * @returns the initialized OOVASTAd
 */
- (id)initWithXML:(OOTBXMLElement *)xml;

- (void)setAdSequence:(float)adSequence;

/** @internal
 * Update the OOVASTAd using the specified xml (subclasses should override this)
 * @param[in] xml the OOTBXMLElement containing the xml to use to update this OOVASTAd
 * @returns YES if the XML was properly formatter, NO if not
 */
- (BOOL)updateWithXML:(OOTBXMLElement *)xml;

@end
