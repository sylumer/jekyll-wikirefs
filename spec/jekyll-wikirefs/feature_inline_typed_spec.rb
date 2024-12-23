# frozen_string_literal: true

require "jekyll-wikirefs"
require "spec_helper"
require "shared_context"

RSpec.describe(Jekyll::WikiRefs::Generator) do
  include_context "shared jekyll configs"

  let(:config_overrides)              { { "collections" => { "typed" => { "output" => true }, "target" => { "output" => true } } } }
  let(:site)                          { Jekyll::Site.new(config) }

  # links
  let(:link)                          { find_by_title(site.collections["typed"].docs, "Typed Link") }
  let(:link_missing_doc)              { find_by_title(site.collections["typed"].docs, "Typed Link Missing Doc") }
  # targets
  let(:blank_a)                       { find_by_title(site.collections["target"].docs, "Blank A") }
  let(:blank_b)                       { find_by_title(site.collections["target"].docs, "Blank B") }

  # makes markdown tests work
  subject { described_class.new(site.config) }

  before(:each) do
    site.reset
    site.process
  end

  after(:each) do
    # cleanup _site/ dir
    FileUtils.rm_rf(Dir["#{site_dir()}"])
  end

  context "INLINE TYPED [[wikilinks]]" do

    context "when target doc exists" do

      context "html output" do

        it "full" do
          expect(link.output).to eq("<p>This doc contains a wikilink to <a class=\"wiki-link typed inline-typed\" href=\"/target/blank.a/\">blank a</a>.</p>\n")
          expect(blank_a.output).to eq("\n")
        end

        it "injects 'a' tag" do
          expect(link.output).to include("<a")
          expect(link.output).to include("</a>")
        end

        it "assigns 'wiki-link' class to 'a' tag" do
          expect(link.output).to include("class=")
          expect(link.output).to include("wiki-link")
        end

        it "assigns 'typed' class to 'a' tag" do
          expect(link.output).to include("class=")
          expect(link.output).to include("typed")
        end

        it "assigns link type as class to 'a' tag" do
          expect(link.output).to include("class=")
          expect(link.output).to include("inline-typed")
        end

        it "assigns 'a' tag's 'href' to document url" do
          expect(link.output).to include("href=\"/target/blank.a/\"")
        end

        it "generates a clean url when configs assign 'permalink' to 'pretty'" do
          expect(link.output).to_not include(".html")
        end

        it "title in wikilink's rendered text" do
          expect(link.output).to include('>' + blank_a.data['title'] + '<')
        end

      end

      context "metadata:" do

        context "'attributed'" do

          it "not added to document" do
            expect(link.data['attributed']).to eq([])
          end

          it "not added to document" do
            expect(blank_a.data['attributed']).to eq([])
          end

        end

        context "'attributes'" do

          it "not added to document" do
            expect(link.data['attributes']).to eq([])
          end

          it "not added to linked document" do
            expect(blank_a.data['attributes']).to eq([])
          end

        end

        context "'backlinks'" do

          it "not added to original document" do
            expect(link.data['backlinks']).to eq([])
          end

          it "added to linked document" do
            expect(blank_a.data.keys).to include("backlinks")
          end

          it "contains linked doc info; full content" do
            expect(blank_a.data['backlinks']).to include({"type"=>"inline-typed", "url"=>"/typed/link/"})
          end

          it "contain array of hashes with keys 'type' and 'url'" do
            expect(blank_a.data['backlinks']).to be_a(Array)
            expect(blank_a.data['backlinks'][0].keys).to eq([ "type", "url" ])
          end

          it "'type' is the type:: text" do
            expect(blank_a.data['backlinks'][0]['type']).to eq("inline-typed")
          end

          it "'url' is a url str" do
            expect(blank_a.data['backlinks'][0]['url']).to eq("/typed/link/")
          end

        end

        context "'forelinks'" do

          it "added to original document" do
            expect(link.data.keys).to include("attributes")
          end

          it "contains linked doc info; full content" do
            expect(link.data['forelinks']).to include({"type"=>"inline-typed", "url"=>"/target/blank.a/"})
          end

        end

      end

    end

    context "when target doc does not exist" do

      context "html output" do

        it "full" do
          expect(link_missing_doc.output).to eq("<p>This doc contains a wikilink to <span class=\"invalid-wiki-link\">inline-typed::[[missing.doc]]</span>.</p>\n")
        end

        it "injects a span element with descriptive title" do
          expect(link_missing_doc.output).to include("<span ")
          expect(link_missing_doc.output).to include("</span>")
        end

        it "assigns 'invalid-wiki-link' class to span element" do
          expect(link_missing_doc.output).to include("class=\"invalid-wiki-link\"")
        end

        it "leaves original angle brackets and text untouched" do
          expect(link_missing_doc.output).to include("[[missing.doc]]")
        end

        # it "handles header url fragments; full output" do
        #   expect(link_header_missing_doc.output).to eq("<p>This doc contains an invalid link with an invalid header <span class=\"invalid-wiki-link\">[[long-doc#Zero]]</span>.</p>\n")
        # end

      end

      context "metadata:" do

        it "'missing' added to document" do
          expect(link_missing_doc.data['missing']).to eq(["missing.doc"])
        end

        it "'attributed' not added to document" do
          expect(link_missing_doc.data['attributed']).to eq([])
        end

        it "'attributes' not added to document" do
          expect(link_missing_doc.data['attributes']).to eq([])
        end

        it "'backlinks' not added to document" do
          expect(link_missing_doc.data['backlinks']).to eq([])
        end

        it "'forelinks' not added to document" do
          expect(link_missing_doc.data['forelinks']).to eq([])
        end

      end

    end

  end

end
