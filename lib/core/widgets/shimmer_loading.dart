import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final int count;
  const ShimmerLoading({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.white),
                  title: Container(height: 12, color: Colors.white, width: double.infinity),
                  subtitle: Container(height: 10, color: Colors.white, width: 100),
                ),
              ),
            ),
          );
        },
        childCount: count,
      ),
    );
  }
}
