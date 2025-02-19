/*import 'package:eClassify/ui/screens/widgets/animatedRoutes/blur_page_route.dart'
    show BlurredRouter;*/
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/fetch_blogs_cubit.dart';
import 'package:eClassify/data/model/blog_model.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/intertitial_ads_screen.dart';
import 'package:eClassify/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlogsScreen extends StatefulWidget {
  const BlogsScreen({super.key});

  static Route route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) {
        return const BlogsScreen();
      },
    );
  }

  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen> {
  final ScrollController _pageScrollController = ScrollController();

  @override
  void initState() {
    AdHelper.loadInterstitialAd();
    context.read<FetchBlogsCubit>().fetchBlogs();
    _pageScrollController.addListener(pageScrollListen);
    super.initState();
  }

  void pageScrollListen() {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchBlogsCubit>().hasMoreData()) {
        context.read<FetchBlogsCubit>().fetchBlogsMore();
      }
    }
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AdHelper.showInterstitialAd();
    return RefreshIndicator(
      color: context.color.territoryColor,
      onRefresh: () async {
        context.read<FetchBlogsCubit>().fetchBlogs();
      },
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: UiUtils.buildAppBar(context,
            showBackButton: true, title: "blogs".translate(context)),
        body: BlocBuilder<FetchBlogsCubit, FetchBlogsState>(
          builder: (context, state) {
            if (state is FetchBlogsInProgress) {
              return buildBlogsShimmer();
            }
            if (state is FetchBlogsFailure) {
              if (state.errorMessage is ApiException) {
                if (state.errorMessage.error == "no-internet") {
                  return NoInternet(
                    onRetry: () {
                      context.read<FetchBlogsCubit>().fetchBlogs();
                    },
                  );
                }
              }
              return const SomethingWentWrong();
            }
            if (state is FetchBlogsSuccess) {
              if (state.blogModel.isEmpty) {
                return const NoDataFound();
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                        controller: _pageScrollController,
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: state.blogModel.length,
                        itemBuilder: (context, index) {
                          BlogModel blog = state.blogModel[index];

                          return buildBlogCard(context, blog);

                          // return blog(state, index);
                        }),
                  ),
                  if (state.isLoadingMore) const CircularProgressIndicator(),
                  if (state.loadingMoreError)
                    CustomText("somethingWentWrng".translate(context))
                ],
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

  Widget buildBlogCard(BuildContext context, BlogModel blog) {
    return Padding(
        padding: const EdgeInsets.all(7.0),
        child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                Routes.blogDetailsScreenRoute,
                arguments: {
                  "model": blog,
                },
              );
            },
            child: Container(
                width: double.infinity,
                // height: 290,
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: context.color.borderColor.darken(40),
                  ),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            12.0, 12, 12, 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: UiUtils.getImage(
                            blog.image!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 151,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            12.0, 12, 12, 6),
                        child: CustomText(blog.title ?? "",
                            color: context.color.textColorDark.withOpacity(0.3),
                            fontSize: context.font.normal),
                      )
                    ]))));
  }

  String stripHtmlTags(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    String strippedString = htmlString.replaceAll(exp, '');
    return strippedString;
  }

  Widget buildBlogsShimmer() {
    return ListView.builder(
        itemCount: 10,
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ClipRRect(
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                height: 287,
                decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    border: Border.all(
                        width: 1.5, color: context.color.borderColor)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomShimmer(
                      width: double.infinity,
                      height: 160,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: CustomShimmer(
                        width: 100,
                        height: 10,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: CustomShimmer(
                        width: 160,
                        height: 10,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: CustomShimmer(
                        width: 150,
                        height: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
