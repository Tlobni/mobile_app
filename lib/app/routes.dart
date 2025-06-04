import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tlobni/ui/screens/ad_details_screen/ad_details_screen.dart';
import 'package:tlobni/ui/screens/advertisement/my_advertisment_screen.dart';
import 'package:tlobni/ui/screens/auth/account_type/account_type_screen.dart';
import 'package:tlobni/ui/screens/auth/login/forgot_password.dart';
import 'package:tlobni/ui/screens/auth/login/login_screen.dart';
import 'package:tlobni/ui/screens/auth/sign_up/mobile_signup_screen.dart';
import 'package:tlobni/ui/screens/auth/sign_up/signup_main_screen.dart';
import 'package:tlobni/ui/screens/auth/sign_up/signup_screen.dart';
import 'package:tlobni/ui/screens/blogs/blog_details.dart';
import 'package:tlobni/ui/screens/blogs/blogs_screen.dart';
import 'package:tlobni/ui/screens/chat/blocked_user_list_screen.dart';
import 'package:tlobni/ui/screens/faqs_screen.dart';
import 'package:tlobni/ui/screens/favorite_screen.dart';
import 'package:tlobni/ui/screens/filter_category_screen.dart';
import 'package:tlobni/ui/screens/home/category_list.dart';
import 'package:tlobni/ui/screens/home/change_language_screen.dart';
import 'package:tlobni/ui/screens/home/featured_users_screen.dart';
import 'package:tlobni/ui/screens/home/search_screen.dart';
import 'package:tlobni/ui/screens/home/widgets/categoryFilterScreen.dart';
import 'package:tlobni/ui/screens/home/widgets/posted_since_filter.dart';
import 'package:tlobni/ui/screens/home/widgets/sub_category_filter.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/add_item_details.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/confirm_location_screen.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/more_details.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/select_category.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/select_post_type.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/widgets/pdf_viewer.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/widgets/success_item_screen.dart';
import 'package:tlobni/ui/screens/item/items_list.dart';
import 'package:tlobni/ui/screens/item/my_items/my_items_screen.dart';
import 'package:tlobni/ui/screens/item/view_all_screen.dart';
import 'package:tlobni/ui/screens/location/areas_screen.dart';
import 'package:tlobni/ui/screens/location/cities_screen.dart';
import 'package:tlobni/ui/screens/location/countries_screen.dart';
import 'package:tlobni/ui/screens/location/nearby_location.dart';
import 'package:tlobni/ui/screens/location/states_screen.dart';
import 'package:tlobni/ui/screens/location_permission_screen.dart';
import 'package:tlobni/ui/screens/main_activity.dart';
import 'package:tlobni/ui/screens/my_review_screen.dart';
import 'package:tlobni/ui/screens/seller/seller_intro_verification.dart';
import 'package:tlobni/ui/screens/seller/seller_profile.dart';
import 'package:tlobni/ui/screens/seller/seller_verification.dart';
import 'package:tlobni/ui/screens/seller/seller_verification_complete.dart';
import 'package:tlobni/ui/screens/settings/contact_us.dart';
import 'package:tlobni/ui/screens/settings/notification_detail.dart';
import 'package:tlobni/ui/screens/settings/notifications.dart';
import 'package:tlobni/ui/screens/settings/profile_setting.dart';
import 'package:tlobni/ui/screens/sold_out_bought_screen.dart';
import 'package:tlobni/ui/screens/splash_screen.dart';
import 'package:tlobni/ui/screens/sub_category/sub_category_screen.dart';
import 'package:tlobni/ui/screens/subscription/packages_list.dart';
import 'package:tlobni/ui/screens/subscription/transaction_history_screen.dart';
import 'package:tlobni/ui/screens/user_profile/edit_profile.dart';
import 'package:tlobni/ui/screens/welcome/welcome_screen.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/maintenance_mode.dart';
import 'package:tlobni/utils/constant.dart';

class Routes {
  static const splash = 'splash';
  static const onboarding = 'onboarding';
  static const welcome = 'welcome';
  static const accountType = 'accountType';
  static const login = 'login';
  static const forgotPassword = 'forgotPassword';
  static const signup = 'signup';
  static const signupMainScreen = 'signUpMainScreen';
  static const mobileSignUp = 'mobileSignUp';
  static const completeProfile = 'complete_profile';
  static const main = 'main';
  static const home = 'Home';
  static const addItem = 'addItem';
  static const waitingScreen = 'waitingScreen';
  static const categories = 'Categories';
  static const addresses = 'address';
  static const chooseAddress = 'chooseAddress';
  static const itemsList = 'itemsList';
  static const contactUs = 'ContactUs';
  static const profileSettings = 'profileSettings';
  static const filterScreen = 'filterScreen';
  static const notificationPage = 'notificationpage';
  static const notificationDetailPage = 'notificationdetailpage';
  static const addItemScreenRoute = 'addItemScreenRoute';
  static const blogsScreenRoute = 'blogsScreenRoute';
  static const subscriptionPackageListRoute = 'subscriptionPackageListRoute';
  static const subscriptionScreen = 'subscriptionScreen';
  static const maintenanceMode = '/maintenanceMode';
  static const favoritesScreen = '/favoritescreen';
  static const promotedItemsScreen = '/promotedItemsScreen';
  static const mostLikedItemsScreen = '/mostLikedItemsScreen';
  static const mostViewedItemsScreen = '/mostViewedItemsScreen';
  static const blogDetailsScreenRoute = '/blogDetailsScreenRoute';
  static const myReviewsScreen = '/myReviewsScreenRoute';

  static const languageListScreenRoute = '/languageListScreenRoute';
  static const searchScreenRoute = '/searchScreenRoute';
  static const itemMapScreen = '/ItemMap';
  static const dashboard = '/dashboard';
  static const subCategoryScreen = '/subCategoryScreen';
  static const categoryFilterScreen = '/categoryFilterScreen';
  static const subCategoryFilterScreen = '/subCategoryFilterScreen';
  static const postedSinceFilterScreen = '/postedSinceFilterScreen';
  static const locationPermissionScreen = '/locationPermissionScreen';
  static const sellerProfileScreen = '/sellerProfileScreen';
  static const nearbyLocationScreen = '/nearbyLocationScreen';

  static const myAdvertisment = '/myAdvertisment';
  static const transactionHistory = '/transactionHistory';
  static const personalizedItemScreen = '/personalizedItemScreen';
  static const myItemScreen = '/myItemScreen';
  static const pdfViewerScreen = '/pdfViewerScreen';
  static const countriesScreen = '/countriesScreen';
  static const statesScreen = '/statesScreen';
  static const citiesScreen = '/citiesScreen';
  static const areasScreen = '/areasScreen';
  static const faqsScreen = '/faqsScreen';
  static const soldOutBoughtScreen = '/soldOutBoughtScreen';
  static const sellerIntroVerificationScreen = '/sellerIntroVerificationScreen';
  static const sellerVerificationScreen = '/sellerVerificationScreen';
  static const sellerVerificationComplteScreen = '/sellerVerificationComplteScreen';

  ///Add Item screens
  static const selectItemTypeScreen = '/selectItemType';
  static const addItemDetailsScreen = '/addItemDetailsScreen';
  static const setItemParametersScreen = '/setItemParametersScreen';
  static const selectOutdoorFacility = '/selectOutdoorFacility';
  static const adDetailsScreen = '/adDetailsScreen';
  static const successItemScreen = '/successItemScreen';

  ///Add item screens
  static const selectCategoryScreen = '/selectCategoryScreen';
  static const selectNestedCategoryScreen = '/selectNestedCategoryScreen';
  static const addItemDetails = '/addItemDetails';
  static const addMoreDetailsScreen = '/addMoreDetailsScreen';
  static const confirmLocationScreen = '/confirmLocationScreen';
  static const sectionWiseItemsScreen = '/sectionWiseItemsScreen';
  static const blockedUserListScreen = '/blockedUserListScreen';
  static const payStackWebViewScreen = '/payStackWebViewScreen';

  //Sandbox[test]
  static const playground = 'playground';

  static const selectPostTypeScreen = '/selectPostTypeScreen';

  // Add the new route constant
  static const featuredUsersScreen = '/featuredUsersScreen';

  static String currentRoute = '';
  static String previousRoute = '';

  static Route onGenerateRouted(RouteSettings routeSettings) {
    previousRoute = currentRoute;

    print('$previousRoute -> $currentRoute');

    if (routeSettings.name!.contains('/product-details/')) {
      final itemSlug = routeSettings.name!.split('/').last;
      if (previousRoute.isEmpty) {
        return BlurredRouter(
            builder: ((context) => SplashScreen(
                  itemSlug: itemSlug,
                )));
      } else {
        //Pop the current route if it is adDetailsScreen otherwise multiple adDetailsScreen will be added
        //when navigating through deep links
        if (currentRoute == adDetailsScreen) {
          Constant.navigatorKey.currentState?.pop();
        }
        return AdDetailsScreen.route(RouteSettings(arguments: {"slug": itemSlug}));
      }
    }
    currentRoute = routeSettings.name ?? "";

    switch (routeSettings.name) {
      case splash:
        return BlurredRouter(builder: ((context) => const SplashScreen()));
      case onboarding:
        return CupertinoPageRoute(builder: ((context) => const WelcomeScreen()));
      case welcome:
        return WelcomeScreen.route(routeSettings);
      case accountType:
        return AccountTypeScreen.route(routeSettings);
      case main:
        return MainActivity.route(routeSettings);
      case login:
        return LoginScreen.route(routeSettings);
      case forgotPassword:
        return ForgotPasswordScreen.route(routeSettings);
      case signup:
        return SignupScreen.route(routeSettings);
      case signupMainScreen:
        return SignUpMainScreen.route(routeSettings);
      case mobileSignUp:
        return MobileSignUpScreen.route(routeSettings);
      case completeProfile:
        return UserProfileScreen.route(routeSettings);

      case categories:
        return CategoryList.route(routeSettings);
      case subCategoryScreen:
        return SubCategoryScreen.route(routeSettings);
      case categoryFilterScreen:
        return CategoryFilterScreen.route(routeSettings);
      case subCategoryFilterScreen:
        return SubCategoryFilterScreen.route(routeSettings);
      case postedSinceFilterScreen:
        return PostedSinceFilterScreen.route(routeSettings);
      case maintenanceMode:
        return MaintenanceMode.route(routeSettings);
      case languageListScreenRoute:
        return LanguagesListScreen.route(routeSettings);
      case contactUs:
        return ContactUs.route(routeSettings);
      case locationPermissionScreen:
        return LocationPermissionScreen.route(routeSettings);
      case profileSettings:
        return ProfileSettings.route(routeSettings);
      case filterScreen:
        return FilterScreen.route(routeSettings);
      case notificationPage:
        return Notifications.route(routeSettings);
      case notificationDetailPage:
        return NotificationDetail.route(routeSettings);
      case blogsScreenRoute:
        return BlogsScreen.route(routeSettings);
      case successItemScreen:
        return SuccessItemScreen.route(routeSettings);

      case blogDetailsScreenRoute:
        return BlogDetails.route(routeSettings);
      case subscriptionPackageListRoute:
        return SubscriptionPackageListScreen.route(routeSettings);

      case favoritesScreen:
        return FavoriteScreen.route(routeSettings);

      case transactionHistory:
        return TransactionHistory.route(routeSettings);
      case blockedUserListScreen:
        return BlockedUserListScreen.route(routeSettings);
      case countriesScreen:
        return CountriesScreen.route(routeSettings);

      case statesScreen:
        return StatesScreen.route(routeSettings);
      case citiesScreen:
        return CitiesScreen.route(routeSettings);
      case areasScreen:
        return AreasScreen.route(routeSettings);

      case myAdvertisment:
        return MyAdvertisementScreen.route(routeSettings);
      case myItemScreen:
        return ItemsScreen.route(routeSettings);
      case searchScreenRoute:
        return SearchScreen.route(routeSettings);

      case itemsList:
        return ItemsList.route(routeSettings);
      case faqsScreen:
        return FaqsScreen.route(routeSettings);

      //Add item screen
      case selectCategoryScreen:
        return SelectCategoryScreen.route(routeSettings);
      case selectNestedCategoryScreen:
        return SelectNestedCategory.route(routeSettings);
      case addItemDetails:
        return AddItemDetails.route(routeSettings);
      case addMoreDetailsScreen:
        return AddMoreDetailsScreen.route(routeSettings);

      case confirmLocationScreen:
        return ConfirmLocationScreen.route(routeSettings);
      case sectionWiseItemsScreen:
        return SectionItemsScreen.route(routeSettings);

      case adDetailsScreen:
        return AdDetailsScreen.route(routeSettings);

      case pdfViewerScreen:
        return PdfViewer.route(routeSettings);
      case soldOutBoughtScreen:
        return SoldOutBoughtScreen.route(routeSettings);
      case sellerProfileScreen:
        return SellerProfileScreen.route(routeSettings);
      case sellerIntroVerificationScreen:
        return SellerIntroVerificationScreen.route(routeSettings);
      case sellerVerificationScreen:
        return SellerVerificationScreen.route(routeSettings);
      case sellerVerificationComplteScreen:
        return SellerVerificationCompleteScreen.route(routeSettings);
      case nearbyLocationScreen:
        return NearbyLocationScreen.route(routeSettings);
      case myReviewsScreen:
        return MyReviewScreen.route(routeSettings);

      case selectPostTypeScreen:
        return SelectPostTypeScreen.route(routeSettings);

      // Add the new route case
      case featuredUsersScreen:
        return FeaturedUsersScreen.route(routeSettings);

      default:
        return CupertinoPageRoute(builder: (context) => const Scaffold());
    }
  }
}
