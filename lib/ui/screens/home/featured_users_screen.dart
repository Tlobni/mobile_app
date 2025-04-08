import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';

class FeaturedUsersScreen extends StatefulWidget {
  final String title;

  const FeaturedUsersScreen({
    super.key,
    required this.title,
  });

  static Route route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return BlurredRouter(
      builder: (_) => FeaturedUsersScreen(
        title: arguments['title'],
      ),
    );
  }

  @override
  _FeaturedUsersScreenState createState() => _FeaturedUsersScreenState();
}

class _FeaturedUsersScreenState extends State<FeaturedUsersScreen> {
  List<dynamic> _featuredUsers = [];
  bool _isLoading = true;
  String? _error;
  bool _hasMore = false;
  int _page = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchFeaturedUsers();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMoreUsers();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchFeaturedUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> parameters = {
        "page": _page,
        if (HiveUtils.getCityName() != null) 'city': HiveUtils.getCityName(),
        if (HiveUtils.getAreaId() != null) 'area_id': HiveUtils.getAreaId(),
        if (HiveUtils.getCountryName() != null)
          'country': HiveUtils.getCountryName(),
        if (HiveUtils.getStateName() != null) 'state': HiveUtils.getStateName(),
      };

      final response =
          await Api.get(url: Api.featuredUsersApi, queryParameters: parameters);

      if (!response[Api.error] && response['data'] != null) {
        List<dynamic> users = [];

        if (response['data']['data'] is List) {
          users = response['data']['data'];
        } else if (response['data'] is List) {
          users = response['data'];
        }

        setState(() {
          _featuredUsers = users;
          _isLoading = false;
          _hasMore = users.length < (response['data']['total'] ?? 0);
        });
      } else {
        setState(() {
          _error = "Failed to load featured users";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _loadMoreUsers() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _page++;
      Map<String, dynamic> parameters = {
        "page": _page,
        if (HiveUtils.getCityName() != null) 'city': HiveUtils.getCityName(),
        if (HiveUtils.getAreaId() != null) 'area_id': HiveUtils.getAreaId(),
        if (HiveUtils.getCountryName() != null)
          'country': HiveUtils.getCountryName(),
        if (HiveUtils.getStateName() != null) 'state': HiveUtils.getStateName(),
      };

      final response =
          await Api.get(url: Api.featuredUsersApi, queryParameters: parameters);

      if (!response[Api.error] && response['data'] != null) {
        List<dynamic> newUsers = [];

        if (response['data']['data'] is List) {
          newUsers = response['data']['data'];
        } else if (response['data'] is List) {
          newUsers = response['data'];
        }

        setState(() {
          _featuredUsers.addAll(newUsers);
          _isLoadingMore = false;
          _hasMore = _featuredUsers.length < (response['data']['total'] ?? 0);
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiUtils.buildAppBar(context,
          showBackButton: true, title: widget.title),
      body: RefreshIndicator(
        onRefresh: () async {
          _page = 1;
          _fetchFeaturedUsers();
        },
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }

    if (_error != null) {
      if (_error == "no-internet") {
        return NoInternet(onRetry: _fetchFeaturedUsers);
      }
      return SomethingWentWrong();
    }

    if (_featuredUsers.isEmpty) {
      return Center(
        child: NoDataFound(onTap: _fetchFeaturedUsers),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _featuredUsers.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _featuredUsers.length) {
          return Center(
            child: CircularProgressIndicator(
              color: context.color.territoryColor,
            ),
          );
        }

        final user = _featuredUsers[index];

        // Get categories as a formatted string
        String categoryName = "Category";
        if (user['categories'] != null) {
          try {
            List<String> categories = user['categories'].toString().split(',');
            if (categories.isNotEmpty) {
              categoryName = categories.first;
            }
          } catch (e) {
            // Use default if there's an error parsing
          }
        }

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              if (user['id'] != null) {
                // Create a User object from the featured user data
                User userModel = User(
                  id: user['id'],
                  name: user['name'],
                  profile: user['profile'],
                  type: user['type'],
                  bio: user['bio'],
                  email: user['email'],
                  mobile: user['mobile'],
                  address: user['address'] ?? user['location'],
                  isVerified: user['is_verified'],
                  createdAt: user['created_at'],
                  facebook: user['facebook'],
                  twitter: user['twitter'],
                  instagram: user['instagram'],
                  tiktok: user['tiktok'],
                  showPersonalDetails: user['show_personal_details'],
                );

                // Navigate to seller profile with proper model
                Navigator.pushNamed(
                  context,
                  Routes.sellerProfileScreen,
                  arguments: {
                    "model": userModel,
                    "rating": 0.0, // Default rating
                    "total": 0, // Default total reviews
                  },
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // User image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: user['profile'] != null &&
                            user['profile'].toString().isNotEmpty
                        ? UiUtils.getImage(
                            user['profile'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color:
                                context.color.territoryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: context.color.territoryColor,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),

                  // User details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user['name'] ?? "Expert",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user['is_verified'] == 1)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: context.color.forthColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    CustomText(
                                      "Verified",
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Type and Category
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6CBA8).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user['type'] ?? "Expert",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.color.territoryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: context.color.territoryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                categoryName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.color.territoryColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Location
                        if (user['location'] != null || user['address'] != null)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: context.color.textLightColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  user['location'] ?? user['address'] ?? "",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.color.textLightColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                        // Total listings
                        if (user['items_count'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "${user['items_count']} Listings",
                              style: TextStyle(
                                fontSize: 12,
                                color: context.color.textLightColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Arrow indicator
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: context.color.textLightColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // User image shimmer
                CustomShimmer(
                  width: 80,
                  height: 80,
                  borderRadius: 40,
                ),
                const SizedBox(width: 16),

                // User details shimmer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomShimmer(height: 20, width: 150),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CustomShimmer(height: 16, width: 80),
                          const SizedBox(width: 8),
                          CustomShimmer(height: 16, width: 80),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CustomShimmer(height: 16, width: 200),
                      const SizedBox(height: 8),
                      CustomShimmer(height: 14, width: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
