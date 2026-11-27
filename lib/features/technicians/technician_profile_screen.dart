import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/app_chips.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/remote_image.dart';
import '../../core/widgets/section_header.dart';
import '../../models/review.dart';
import '../../models/technician.dart';
import '../../repositories/customer_repository.dart';
import '../favorites/favorites_cubit.dart';
import '../home/home_cubit.dart';

class TechnicianProfileScreen extends StatelessWidget {
  const TechnicianProfileScreen({super.key, required this.technicianId});

  final String technicianId;

  @override
  Widget build(BuildContext context) {
    final technician = context.watch<HomeCubit>().state.technicianById(
      technicianId,
    );
    if (technician == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ملف الفني')),
        body: const Center(child: Text('الفني غير متاح حاليًا')),
      );
    }
    final favorite = context.watch<FavoritesCubit>().state.contains(
      technician.id,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف الفني'),
        actions: <Widget>[
          IconButton(
            onPressed: () =>
                context.read<FavoritesCubit>().toggle(technician.id),
            icon: Icon(
              favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: favorite ? AppColors.danger : null,
            ),
          ),
          IconButton(
            onPressed: () =>
                UiUtils.showSnackBar(context, 'رقم الفني: ${technician.id}'),
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Stack(
              children: <Widget>[
                RemoteImage(
                  url: technician.imageUrl,
                  base64Data: technician.imageBase64,
                  width: double.infinity,
                  height: 285,
                  borderRadius: 24,
                ),
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: AvailabilityChip(available: technician.isAvailable),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              technician.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(width: 7),
                          if (technician.isVerified)
                            const VerifiedBadge(compact: false),
                        ],
                      ),
                      Text(
                        technician.profession,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                RatingBadge(
                  rating: technician.rating,
                  reviews: technician.reviewsCount,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: <Widget>[
                  _ProfileStat(
                    icon: Icons.work_outline_rounded,
                    value: '${technician.completedJobs}+',
                    label: 'عمل مكتمل',
                  ),
                  const _VerticalDivider(),
                  _ProfileStat(
                    icon: Icons.workspace_premium_outlined,
                    value: '${technician.experienceYears}',
                    label: 'سنوات خبرة',
                  ),
                  const _VerticalDivider(),
                  _ProfileStat(
                    icon: Icons.near_me_outlined,
                    value: '${technician.distanceKm}',
                    label: 'كم بعيدًا',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'نبذة عن الفني'),
            const SizedBox(height: 8),
            Text(technician.bio, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 21),
            const SectionHeader(title: 'الخدمات'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: technician.services
                  .map(
                    (service) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.powderBlue,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        service,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (technician.portfolioUrls.isNotEmpty) ...<Widget>[
              const SizedBox(height: 22),
              const SectionHeader(title: 'أعمال سابقة'),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: technician.portfolioUrls.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 9,
                  mainAxisSpacing: 9,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (_, index) => RemoteImage(
                  url: technician.portfolioUrls[index],
                  borderRadius: 15,
                ),
              ),
            ],
            const SizedBox(height: 22),
            const SectionHeader(title: 'تقييمات العملاء'),
            const SizedBox(height: 10),
            _ReviewsList(technician: technician),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: PrimaryButton(
            label: technician.isAvailable ? 'اطلب الخدمة' : 'احجز موعد',
            icon: Icons.arrow_back_rounded,
            height: 52,
            onPressed: technician.canReceiveOrders
                ? () => context.push('/request/${technician.id}')
                : null,
          ),
        ),
      ),
    );
  }
}

class _ReviewsList extends StatelessWidget {
  const _ReviewsList({required this.technician});

  final Technician technician;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TechnicianReview>>(
      stream: context.read<CustomerRepository>().watchReviews(technician.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reviews = snapshot.data ?? const <TechnicianReview>[];
        if (reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'لسه مفيش تقييمات مكتوبة للفني.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          );
        }
        return Column(
          children: reviews
              .take(4)
              .map((review) => _ReviewCard(review: review))
              .toList(),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final TechnicianReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.powderPeach,
                child: Text(
                  review.customerName.isEmpty ? 'ح' : review.customerName[0],
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  review.customerName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              RatingBadge(rating: review.rating.toDouble()),
            ],
          ),
          if (review.comment.isNotEmpty) ...<Widget>[
            const SizedBox(height: 9),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Icon(icon, color: AppColors.orange, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 45, color: AppColors.border);
}
