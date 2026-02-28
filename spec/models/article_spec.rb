require 'rails_helper'

RSpec.describe Article, type: :model do
  describe "associations" do
    it "belongs to author (User)" do
      article = build(:article)
      expect(article.author).to be_a(User)
    end

    it "allows nil author" do
      article = build(:article, author: nil)
      expect(article).to be_valid
    end
  end

  describe "validations" do
    it "validates presence of title" do
      article = build(:article, title: nil)
      expect(article).not_to be_valid
      expect(article.errors[:title]).to be_present
    end

    it "validates length of title" do
      article = build(:article, title: "a" * 101)
      expect(article).not_to be_valid
      expect(article.errors[:title]).to be_present
    end

    it "auto-generates slug when nil" do
      article = build(:article, slug: nil)
      article.valid?
      expect(article.slug).to be_present
      expect(article.slug).to match(/^[a-z0-9-]+$/)
    end

    it "validates uniqueness of slug" do
      create(:article, slug: "duplicate")
      article = build(:article, slug: "duplicate")
      expect(article).not_to be_valid
      expect(article.errors[:slug]).to be_present
    end

    it "validates length of slug" do
      article = build(:article, slug: "a" * 101)
      expect(article).not_to be_valid
      expect(article.errors[:slug]).to be_present
    end

    it "validates presence of content" do
      article = build(:article, content: nil)
      expect(article).not_to be_valid
      expect(article.errors[:content]).to be_present
    end

    it "validates presence of category" do
      article = build(:article, category: nil)
      expect(article).not_to be_valid
      expect(article.errors[:category]).to be_present
    end

    it "validates slug format" do
      article = build(:article, slug: "Invalid Slug!")
      expect(article).not_to be_valid
      expect(article.errors[:slug]).to be_present
    end

    it "allows valid slug format" do
      article = build(:article, slug: "valid-slug-123")
      expect(article).to be_valid
    end
  end

  describe "enums" do
    it "defines category enum" do
      expect(Article.categories.keys).to match_array(%w[
        typing_tips keyboard_basics keyboard_reviews
        customization typnix_guides community
      ])
    end
  end

  describe "scopes" do
    let!(:published_article) { create(:article, published_at: 1.day.ago) }
    let!(:draft_article) { create(:article, :draft) }
    let!(:scheduled_article) { create(:article, :scheduled) }
    let!(:popular_article) { create(:article, :popular, published_at: 2.days.ago) }

    describe ".published" do
      it "returns only published articles" do
        expect(Article.published).to include(published_article, popular_article)
        expect(Article.published).not_to include(draft_article, scheduled_article)
      end
    end

    describe ".recent" do
      it "returns articles ordered by published_at desc" do
        recent_articles = Article.recent.to_a
        expect(recent_articles).to include(scheduled_article, published_article, popular_article, draft_article)
        # Scheduled article has future date, should be first
        published_dates = recent_articles.map(&:published_at).compact
        expect(published_dates).to eq(published_dates.sort.reverse)
      end
    end

    describe ".by_category" do
      let!(:keyboard_article) { create(:article, :keyboard_basics) }

      it "returns articles in specified category" do
        expect(Article.by_category(:keyboard_basics)).to include(keyboard_article)
        expect(Article.by_category(:keyboard_basics)).not_to include(published_article)
      end
    end

    describe ".popular" do
      it "returns articles ordered by view_count desc" do
        expect(Article.popular.first).to eq(popular_article)
      end
    end
  end

  describe "#published?" do
    it "returns true for published articles" do
      article = build(:article, published_at: 1.day.ago)
      expect(article).to be_published
    end

    it "returns false for draft articles" do
      article = build(:article, :draft)
      expect(article).not_to be_published
    end

    it "returns false for scheduled articles" do
      article = build(:article, :scheduled)
      expect(article).not_to be_published
    end
  end

  describe "#to_param" do
    it "returns slug instead of id" do
      article = build(:article, slug: "my-article")
      expect(article.to_param).to eq("my-article")
    end
  end

  describe "#increment_view_count!" do
    it "increments view_count by 1" do
      article = create(:article, view_count: 5)
      expect { article.increment_view_count! }.to change { article.reload.view_count }.from(5).to(6)
    end
  end

  describe "#author_name" do
    it "returns author's display_name when author exists" do
      user = create(:user, username: "testuser")
      article = build(:article, author: user)
      expect(article.author_name).to eq("testuser")
    end

    it "returns 'Typnix' when author is nil" do
      article = build(:article, author: nil)
      expect(article.author_name).to eq("Typnix")
    end
  end

  describe "slug generation" do
    it "auto-generates slug from title if slug is blank" do
      # Japanese characters won't parameterize well, so use English title
      article = create(:article, title: "What is Split Keyboard", slug: "")
      expect(article.slug).to eq("what-is-split-keyboard")
    end

    it "does not override manually set slug" do
      article = create(:article, title: "Test Title", slug: "custom-slug")
      expect(article.slug).to eq("custom-slug")
    end

    it "generates unique slug when duplicate exists" do
      create(:article, title: "Test", slug: "test")
      article = create(:article, title: "Test", slug: "")
      expect(article.slug).to eq("test-1")
    end
  end
end
