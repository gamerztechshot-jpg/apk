import 'package:flutter/material.dart';
import '../../model/teacher_model.dart';

class TeacherAvatar extends StatelessWidget {
  final TeacherModel teacher;
  final VoidCallback? onTap;

  const TeacherAvatar({super.key, required this.teacher, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 85,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            // Avatar with Border
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade200, width: 2),
              ),
              child: CircleAvatar(
                radius: 34,
                backgroundColor: Colors.orange.shade50,
                backgroundImage:
                    teacher.profileImage != null &&
                        teacher.profileImage!.startsWith('http')
                    ? NetworkImage(teacher.profileImage!)
                    : null,
                child:
                    teacher.profileImage == null ||
                        !teacher.profileImage!.startsWith('http')
                    ? Icon(
                        Icons.person,
                        color: Colors.orange.shade300,
                        size: 35,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),

            // Name
            Text(
              teacher.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),

            // Specialty
            const SizedBox(height: 2),
            Text(
              teacher.specialty,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
