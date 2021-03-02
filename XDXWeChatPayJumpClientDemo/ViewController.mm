//
//  ViewController.m
//  XDXWeChatPayJumpClientDemo
//
//  Created by 小东邪 on 2018/11/1.
//  Copyright © 2018 小东邪. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "log4cplus.h"
#import "TVUMJRefresh.h"

/*
    本例亲测可以正常跳转及返回

        GitHub地址(附代码) :

 */



#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

#define XDX_URL_TIMEOUT 10

static const char *ModuleName = "XDXTestVC";

#warning Note : xdx.web.guangdianyun.tv -> 您必须在Info.plist中配置它。1. "xdx"前缀可以写任何值。2. 你必须用微信注册你的公司正确的域名。如果您的域是错误的，它将显示 "商家参数格式错误，请联系商家解决";

//商户申请H5支付时提交的授权域名，使用时请更换自己的域名
static const NSString *CompanyFirstDomainByWeChatRegister = @"web.guangdianyun.tv";
//xdx 为前缀，可任意填写
static const NSString *CustomByWeChatRegister = @"xdx";

@interface ViewController ()<WKNavigationDelegate>

@property (nonatomic, strong) WKWebView         *webView;
@property (nonatomic, strong) UIProgressView    *progressView;

@property (nonatomic, copy  ) NSString *yourWebAddress;

@end

@implementation ViewController

#pragma mark - View Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupUI];
    [self initWebView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - Init
- (void)initWebView {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.preferences = [[WKPreferences alloc] init];
    config.preferences.javaScriptEnabled=YES;
    
    CGFloat webViewY = self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, webViewY, kScreenWidth, kScreenHeight-webViewY) configuration:config];
    
#warning 填写你的WebView加载地址
    self.yourWebAddress = @"https://web.guangdianyun.tv/gather/?id=1515&uin=3512";
    log4cplus_info("XDX_LOG", "%s - The web view address is %s",ModuleName, self.yourWebAddress.UTF8String);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.yourWebAddress] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:XDX_URL_TIMEOUT];
    [self.webView loadRequest:request];
    
    TVUMJRefreshNormalHeader *header = [TVUMJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(headerRefresh)];
    [header setTitle:@"Pull down to refresh" forState:TVUMJRefreshStateIdle];
    [header setTitle:@"Release to refresh" forState:TVUMJRefreshStatePulling];
    [header setTitle:@"Loading ..." forState:TVUMJRefreshStateRefreshing];
    header.lastUpdatedTimeLabel.hidden = YES;
    self.webView.scrollView.mj_header = header;
    
    [self.view addSubview:self.webView];
    
    //    _webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    
    [self initProgressView];
    
    // Listen the web load condition
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)initProgressView {
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 0.8)];
    self.progressView.progressTintColor = [UIColor greenColor];
    //设置进度条的高度，下面这句代码表示进度条的宽度变为原来的1倍，高度变为原来的1.5倍.
    self.progressView.transform = CGAffineTransformMakeScale(1.0f, 1.5f);
    [self.webView addSubview:self.progressView];
}

#pragma mark - UI
- (void)setupUI {
    self.title = @"XDX's World";
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(didClickBackBtn)];
    item.tintColor = [UIColor blackColor];
    [self.navigationItem setLeftBarButtonItem:item];
}

- (void)headerRefresh{
    // If user enter our app (not network), the URL is NULL even if we have already setted.
    if (!self.webView.URL) {
        log4cplus_error("XDX_LOG", "Refresh webview error, current URL is NULL !");
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.yourWebAddress] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:XDX_URL_TIMEOUT];
        [self.webView loadRequest:request];
    }
    [self.webView reload];
}

- (void)endRefresh{
    [self.webView.scrollView.mj_header endRefreshing];
}

#pragma mark - Button Action
- (void)didClickBackBtn {
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
}

#pragma mark - Notificaiton
#pragma webView progress view
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([self.progressView isDescendantOfView:self.webView]) {
        if ([keyPath isEqualToString:@"estimatedProgress"]) {
            self.progressView.progress = self.webView.estimatedProgress;
            if (self.progressView.progress == 1) {
                /*
                 *添加一个简单的动画，将progressView的Height变为1.4倍，在开始加载网页的代理中会恢复为1.5倍
                 *动画时长0.25s，延时0.3s后开始动画
                 *动画结束后将progressView隐藏
                 */
                
                __weak ViewController *weakSelf = self;
                [UIView animateWithDuration:0.25f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    weakSelf.progressView.transform = CGAffineTransformMakeScale(1.0f, 1.4f);
                } completion:^(BOOL finished) {
                    weakSelf.progressView.hidden = YES;
                    
                }];
            }
        }else{
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
}

#pragma mark - Delegate
#pragma mark - WKNavigation Delegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSURLRequest *request        = navigationAction.request;
    NSString     *scheme         = [request.URL scheme];
    // decode for all URL to avoid url contains some special character so that it wasn't load.
    //解码所有的URL，以避免URL包含一些特殊字符，使它没有加载。
    NSString     *absoluteString = [navigationAction.request.URL.absoluteString stringByRemovingPercentEncoding];
    NSLog(@"Current URL is %@",absoluteString);
    
    static NSString *endPayRedirectURL = nil;
    
    // Wechat Pay, Note : modify redirect_url to resolve we couldn't return our app from wechat client.
/**
 拦截微信支付地址
 
 前缀https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb的网址，该网址即为进行微信支付
 
 拦截后我们需要首先关注在原始地址中是否含有redirect_url=字符串，如果含有该字符串则说明你们后台人员是利用该字符串在微信支付完成后跳转到支付完成的界面.而我们也需要利用该字段以实现支付完成后跳转回我们的APP.
 
 如果包含redirect_url=字段，我们需要先记住后台重定向的地址，然后将其替换成我们配置好的URL schemes以实现跳转回我们的APP.然后在跳转回我们APP之后我们会手动再加载一次原先重定向的URL地址。
 
 如果不包含redirect_url=字段，我们只需要添加该字段到原始URL最后面即可
 
 使用[[UIApplication sharedApplication] openURL:request.URL];即可打开微信客户端
 */
    if ([absoluteString hasPrefix:@"https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb"] && ![absoluteString hasSuffix:[NSString stringWithFormat:@"redirect_url=%@.%@://",CustomByWeChatRegister,CompanyFirstDomainByWeChatRegister]]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        
#warning Note : 这个字符串 "web.guangdianyun.tv://" 必须在微信后台配置。这一定是贵公司的第一要做的。您还应该在 Info.plist 文件中配置 "URL types"
        
        // 1. If the url contain "redirect_url" : We need to remember it to use our scheme replace it.
        // 2. If the url not contain "redirect_url" , We should add it so that we will could jump to our app.
        //  Note : 2. if the redirect_url is not last string, you should use correct strategy, because the redirect_url's value may contain some "&" special character so that my cut method may be incorrect.
        NSString *redirectUrl = nil;
        if ([absoluteString containsString:@"redirect_url="]) {
            NSRange redirectRange = [absoluteString rangeOfString:@"redirect_url"];
            endPayRedirectURL =  [absoluteString substringFromIndex:redirectRange.location+redirectRange.length+1];
            redirectUrl = [[absoluteString substringToIndex:redirectRange.location] stringByAppendingString:[NSString stringWithFormat:@"redirect_url=%@.%@://",CustomByWeChatRegister,CompanyFirstDomainByWeChatRegister]];
        }else {
            redirectUrl = [absoluteString stringByAppendingString:[NSString stringWithFormat:@"&redirect_url=%@.%@://",CustomByWeChatRegister,CompanyFirstDomainByWeChatRegister]];
        }
        
        NSMutableURLRequest *newRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:redirectUrl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:XDX_URL_TIMEOUT];
        newRequest.allHTTPHeaderFields = request.allHTTPHeaderFields;
        newRequest.URL = [NSURL URLWithString:redirectUrl];
        [webView loadRequest:newRequest];
        return;
    }
    
    // Judge is whether to jump to other app.
    if (![scheme isEqualToString:@"https"] && ![scheme isEqualToString:@"http"]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        if ([scheme isEqualToString:@"weixin"]) {
            // The var endPayRedirectURL was our saved origin url's redirect address. We need to load it when we return from wechat client.
            if (endPayRedirectURL) {
                [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:endPayRedirectURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:XDX_URL_TIMEOUT]];
            }
        }else if ([scheme isEqualToString:[NSString stringWithFormat:@"%@.%@",CustomByWeChatRegister,CompanyFirstDomainByWeChatRegister]]) {
            
        }
        
        BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:request.URL];
        if (canOpen) {
            [[UIApplication sharedApplication] openURL:request.URL];
        }
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self endRefresh];
    
    if ([self.progressView isDescendantOfView:self.webView]) {
        self.progressView.hidden = NO;
        self.progressView.transform = CGAffineTransformMakeScale(1.0f, 1.5f);
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSString *absoluteString = self.webView.URL.absoluteString;
    log4cplus_debug("XDX_LOG", "%s - %s : Current URL is %s",ModuleName, __func__, absoluteString.UTF8String);
    
    [self endRefresh];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    log4cplus_error("XDX_LOG", "%s - %s : Error code is %s",ModuleName, __func__, [NSString stringWithFormat:@"%@",error].UTF8String);
    [self endRefresh];
}

#pragma mark Gesture Delegate
// Resolve gesture conflict with webView
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - Other
- (NSString *)getParamValueByName:(NSString *)name URLString:(NSString *)url {
    if (url.length == 0 || name.length == 0) {
        return nil;
    }
    
    NSError *error;
    NSString *regTags = [[NSString alloc] initWithFormat:@"(^|&|\\?)+%@=+([^&]*)(&|$)", name];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regTags
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    // 执行匹配的过程
    NSArray *matches = [regex matchesInString:url
                                      options:0
                                        range:NSMakeRange(0, [url length])];
    for (NSTextCheckingResult *match in matches) {
        NSString *tagValue = [url substringWithRange:[match rangeAtIndex:2]];  // 分组2所对应的串
        return tagValue;
    }
    return nil;
}

- (NSString *)modityParamValueByName:(NSString *)name newValue:(NSString *)newValue URLString:(NSString *)url {
    if (url.length == 0 || name.length == 0) {
        return nil;
    }
    
    NSError *error;
    NSString *regTags = [[NSString alloc] initWithFormat:@"(^|&|\\?)+%@=+([^&]*)(&|$)", name];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regTags
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    // 执行匹配的过程
    NSArray *matches = [regex matchesInString:url
                                      options:0
                                        range:NSMakeRange(0, [url length])];
    for (NSTextCheckingResult *match in matches) {
        NSString *tagValue = [url substringWithRange:[match rangeAtIndex:2]];  // 分组2所对应的串
        NSString *newStr = [url stringByReplacingOccurrencesOfString:tagValue withString:newValue];
        return newStr;
    }
    
    return nil;
}


#pragma mark - Dealloc
- (void)dealloc {
}


@end
