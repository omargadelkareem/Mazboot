"use strict";

const {logger} = require("firebase-functions");
const {onValueWritten} = require("firebase-functions/v2/database");
const {initializeApp} = require("firebase-admin/app");
const {getDatabase} = require("firebase-admin/database");

initializeApp();

/**
 * Publishes only applications approved by an administrator with an active
 * monthly subscription. Change the region if the RTDB instance is not hosted
 * in Belgium (europe-west1).
 */
exports.publishApprovedProvider = onValueWritten(
  {
    ref: "/provider_applications/{providerId}",
    region: "europe-west1",
  },
  async (event) => {
    if (!event.data.after.exists()) return null;

    const application = event.data.after.val();
    const providerId = event.params.providerId;
    const database = getDatabase();
    const providerRef = database.ref(`public_providers/${providerId}`);
    const shouldPublish =
      application.status === "approved" &&
      application.subscriptionActive === true;

    if (!shouldPublish) {
      const providerSnapshot = await providerRef.get();
      const updates = {};
      if (providerSnapshot.exists()) {
        updates[`public_providers/${providerId}/subscriptionActive`] = false;
        updates[`public_providers/${providerId}/isActive`] = false;
      }
      if (application.published === true) {
        updates[`provider_applications/${providerId}/published`] = false;
      }
      if (Object.keys(updates).length === 0) return null;
      await database.ref().update(updates);
      logger.info("Provider unpublished", {providerId});
      return null;
    }

    const [providerSnapshot, categorySnapshot] = await Promise.all([
      providerRef.get(),
      database.ref(`categories/${application.categoryId}`).get(),
    ]);
    if (application.published === true && providerSnapshot.exists()) {
      return null;
    }

    const category = categorySnapshot.val() || {};
    const categoryName = category.name || "خدمات منزلية";
    const existing = providerSnapshot.val() || {};
    const publicProvider = {
      ...existing,
      name: application.name,
      categoryId: application.categoryId,
      profession: `فني ${categoryName}`,
      imageUrl: "",
      imageBase64: application.photoBase64,
      rating: existing.rating || 0,
      reviewsCount: existing.reviewsCount || 0,
      completedJobs: existing.completedJobs || 0,
      distanceKm: existing.distanceKm || 0,
      visitFee: 0,
      isAvailable: true,
      isVerified: true,
      experienceYears: existing.experienceYears || 0,
      bio:
        existing.bio ||
        `${categoryName} في ${application.area}، ${application.governorate}`,
      services: existing.services || [categoryName],
      portfolioUrls: existing.portfolioUrls || [],
      phone: application.phone || existing.phone || "",
      governorate: application.governorate,
      area: application.area,
      latitude: existing.latitude || 0,
      longitude: existing.longitude || 0,
      approvalStatus: "approved",
      subscriptionActive: true,
      subscriptionStartedAt:
        application.subscriptionStartedAt ||
        existing.subscriptionStartedAt ||
        Date.now(),
      subscriptionExpiresAt:
        application.subscriptionExpiresAt ||
        existing.subscriptionExpiresAt ||
        Date.now() + 30 * 24 * 60 * 60 * 1000,
      lastPaymentAt:
        application.lastPaymentAt || existing.lastPaymentAt || Date.now(),
      isActive: true,
    };

    await database.ref().update({
      [`public_providers/${providerId}`]: publicProvider,
      [`provider_applications/${providerId}/published`]: true,
    });
    logger.info("Provider published", {providerId});
    return null;
  },
);
