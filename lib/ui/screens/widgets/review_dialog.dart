import 'package:tlobni/data/cubits/add_user_review_cubit.dart';
import 'package:tlobni/data/helper/widgets.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

enum ReviewType {
  expertProfile,
  businessProfile,
  service,
  experience,
}

class ReviewDialog extends StatefulWidget {
  final int targetId; // User ID or Service ID
  final int? userId; // Owner ID (only needed for service reviews)
  final ReviewType reviewType;
  final String name; // Name of user or service being reviewed
  final String? image; // Optional image of user or service

  const ReviewDialog({
    Key? key,
    required this.targetId,
    this.userId,
    required this.reviewType,
    required this.name,
    this.image,
  }) : super(key: key);

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 5; // Default rating

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.color.secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Center(
        child: CustomText(
          "Rate ${widget.name}",
          fontSize: context.font.larger,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: BlocListener<AddUserReviewCubit, AddUserReviewState>(
        listener: (context, state) {
          print("AddUserReviewCubit state: $state");

          if (state is AddUserReviewInSuccess) {
            print("Review submitted successfully: ${state.responseMessage}");
            Widgets.hideLoder(context);
            Navigator.pop(context, true); // Return success
            HelperUtils.showSnackBarMessage(context, state.responseMessage);
          }
          if (state is AddUserReviewFailure) {
            print("Review submission failed: ${state.error}");
            Widgets.hideLoder(context);
            HelperUtils.showSnackBarMessage(context, state.error.toString());
          }
          if (state is AddUserReviewInProgress) {
            print("Review submission in progress");
            Widgets.showLoader(context);
          }
        },
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Optional image
              if (widget.image != null && widget.image!.isNotEmpty)
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(widget.image!),
                ),
              const SizedBox(height: 15),

              // Rating bar
              RatingBar.builder(
                initialRating: 5.0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 40,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating.toInt();
                  });
                },
              ),
              const SizedBox(height: 15),

              // Review text field
              TextFormField(
                controller: _reviewController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: "Write your review here...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: context.color.borderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: context.color.territoryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: CustomText(
            "Cancel",
            color: context.color.textColorDark,
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.color.territoryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            if (_reviewController.text.trim().isEmpty) {
              HelperUtils.showSnackBarMessage(context, "Please write a review");
              return;
            }

            // Determine which API to call based on review type
            final AddUserReviewCubit cubit = context.read<AddUserReviewCubit>();

            print(
                "Submitting review - Type: ${widget.reviewType}, TargetID: ${widget.targetId}, Rating: $_rating");

            if (widget.reviewType == ReviewType.service ||
                widget.reviewType == ReviewType.experience) {
              // Service or Experience review
              if (widget.userId == null) {
                HelperUtils.showSnackBarMessage(
                    context, "Error: User ID is required for service reviews");
                return;
              }

              print("Service review - UserID: ${widget.userId}");

              // Show temporary debug SnackBar
              HelperUtils.showSnackBarMessage(
                  context, "Submitting service review...",
                  messageDuration: 2);

              cubit.addServiceReview(
                serviceId: widget.targetId,
                userId: widget.userId!,
                rating: _rating,
                review: _reviewController.text.trim(),
              );
            } else {
              // Expert or Business profile review
              print("Profile review - Expert/Business");

              // Show temporary debug SnackBar
              HelperUtils.showSnackBarMessage(
                  context, "Submitting user review...",
                  messageDuration: 2);

              cubit.addUserReview(
                userId: widget.targetId,
                rating: _rating,
                review: _reviewController.text.trim(),
              );
            }
          },
          child: CustomText(
            "Submit",
            color: context.color.buttonColor,
          ),
        ),
      ],
    );
  }
}
