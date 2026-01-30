export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.1"
  }
  public: {
    Tables: {
      articles_r107: {
        Row: {
          content: string | null
          created_at: string
          description: string | null
          id: string
          image_url: string | null
          is_published: boolean
          seo_description: string | null
          seo_title: string | null
          slug: string
          title: string
          updated_at: string
        }
        Insert: {
          content?: string | null
          created_at?: string
          description?: string | null
          id?: string
          image_url?: string | null
          is_published?: boolean
          seo_description?: string | null
          seo_title?: string | null
          slug: string
          title: string
          updated_at?: string
        }
        Update: {
          content?: string | null
          created_at?: string
          description?: string | null
          id?: string
          image_url?: string | null
          is_published?: boolean
          seo_description?: string | null
          seo_title?: string | null
          slug?: string
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      category_subscriptions: {
        Row: {
          category: string
          created_at: string
          id: string
          user_id: string
        }
        Insert: {
          category: string
          created_at?: string
          id?: string
          user_id: string
        }
        Update: {
          category?: string
          created_at?: string
          id?: string
          user_id?: string
        }
        Relationships: []
      }
      comments: {
        Row: {
          content: string
          created_at: string
          id: string
          repair_id: string
          user_id: string
        }
        Insert: {
          content: string
          created_at?: string
          id?: string
          repair_id: string
          user_id: string
        }
        Update: {
          content?: string
          created_at?: string
          id?: string
          repair_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "comments_repair_id_fkey"
            columns: ["repair_id"]
            isOneToOne: false
            referencedRelation: "repairs"
            referencedColumns: ["id"]
          },
        ]
      }
      listing_images: {
        Row: {
          created_at: string
          id: string
          listing_id: string
          sort_order: number | null
          storage_path: string
        }
        Insert: {
          created_at?: string
          id?: string
          listing_id: string
          sort_order?: number | null
          storage_path: string
        }
        Update: {
          created_at?: string
          id?: string
          listing_id?: string
          sort_order?: number | null
          storage_path?: string
        }
        Relationships: [
          {
            foreignKeyName: "listing_images_listing_id_fkey"
            columns: ["listing_id"]
            isOneToOne: false
            referencedRelation: "listings"
            referencedColumns: ["id"]
          },
        ]
      }
      listings: {
        Row: {
          category: Database["public"]["Enums"]["listing_category"]
          country: string | null
          created_at: string
          currency: string | null
          description: string | null
          id: string
          image_url: string | null
          llm_ok: boolean | null
          llm_reason: string | null
          model_tag: string | null
          phone_number: string | null
          price: number | null
          published_at: string | null
          rss_guid: string | null
          rss_source_id: string | null
          source_type: Database["public"]["Enums"]["source_type"]
          status: Database["public"]["Enums"]["listing_status"]
          title: string
          url: string | null
          user_id: string | null
          variant_tag: string | null
          year_from: number | null
          year_to: number | null
        }
        Insert: {
          category?: Database["public"]["Enums"]["listing_category"]
          country?: string | null
          created_at?: string
          currency?: string | null
          description?: string | null
          id?: string
          image_url?: string | null
          llm_ok?: boolean | null
          llm_reason?: string | null
          model_tag?: string | null
          phone_number?: string | null
          price?: number | null
          published_at?: string | null
          rss_guid?: string | null
          rss_source_id?: string | null
          source_type?: Database["public"]["Enums"]["source_type"]
          status?: Database["public"]["Enums"]["listing_status"]
          title: string
          url?: string | null
          user_id?: string | null
          variant_tag?: string | null
          year_from?: number | null
          year_to?: number | null
        }
        Update: {
          category?: Database["public"]["Enums"]["listing_category"]
          country?: string | null
          created_at?: string
          currency?: string | null
          description?: string | null
          id?: string
          image_url?: string | null
          llm_ok?: boolean | null
          llm_reason?: string | null
          model_tag?: string | null
          phone_number?: string | null
          price?: number | null
          published_at?: string | null
          rss_guid?: string | null
          rss_source_id?: string | null
          source_type?: Database["public"]["Enums"]["source_type"]
          status?: Database["public"]["Enums"]["listing_status"]
          title?: string
          url?: string | null
          user_id?: string | null
          variant_tag?: string | null
          year_from?: number | null
          year_to?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "listings_rss_source_id_fkey"
            columns: ["rss_source_id"]
            isOneToOne: false
            referencedRelation: "rss_sources"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_settings: {
        Row: {
          created_at: string
          email_new_comments: boolean
          email_new_listings: boolean
          id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          email_new_comments?: boolean
          email_new_listings?: boolean
          id?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          email_new_comments?: boolean
          email_new_listings?: boolean
          id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      profiles: {
        Row: {
          created_at: string
          display_name: string | null
          email: string
          id: string
        }
        Insert: {
          created_at?: string
          display_name?: string | null
          email: string
          id: string
        }
        Update: {
          created_at?: string
          display_name?: string | null
          email?: string
          id?: string
        }
        Relationships: []
      }
      repair_media: {
        Row: {
          created_at: string
          id: string
          kind: Database["public"]["Enums"]["repair_media_kind"]
          repair_id: string
          sort_order: number | null
          value: string
        }
        Insert: {
          created_at?: string
          id?: string
          kind: Database["public"]["Enums"]["repair_media_kind"]
          repair_id: string
          sort_order?: number | null
          value: string
        }
        Update: {
          created_at?: string
          id?: string
          kind?: Database["public"]["Enums"]["repair_media_kind"]
          repair_id?: string
          sort_order?: number | null
          value?: string
        }
        Relationships: [
          {
            foreignKeyName: "repair_media_repair_id_fkey"
            columns: ["repair_id"]
            isOneToOne: false
            referencedRelation: "repairs"
            referencedColumns: ["id"]
          },
        ]
      }
      repair_modules: {
        Row: {
          content_html: string | null
          id: string
          repair_id: string
          type: Database["public"]["Enums"]["repair_module_type"]
          updated_at: string
        }
        Insert: {
          content_html?: string | null
          id?: string
          repair_id: string
          type: Database["public"]["Enums"]["repair_module_type"]
          updated_at?: string
        }
        Update: {
          content_html?: string | null
          id?: string
          repair_id?: string
          type?: Database["public"]["Enums"]["repair_module_type"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "repair_modules_repair_id_fkey"
            columns: ["repair_id"]
            isOneToOne: false
            referencedRelation: "repairs"
            referencedColumns: ["id"]
          },
        ]
      }
      repair_parts: {
        Row: {
          category_slug: string
          content_html: string
          created_at: string
          id: string
          updated_at: string
        }
        Insert: {
          category_slug: string
          content_html: string
          created_at?: string
          id?: string
          updated_at?: string
        }
        Update: {
          category_slug?: string
          content_html?: string
          created_at?: string
          id?: string
          updated_at?: string
        }
        Relationships: []
      }
      repair_subscriptions: {
        Row: {
          created_at: string
          id: string
          repair_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          repair_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          repair_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "repair_subscriptions_repair_id_fkey"
            columns: ["repair_id"]
            isOneToOne: false
            referencedRelation: "repairs"
            referencedColumns: ["id"]
          },
        ]
      }
      repair_videos: {
        Row: {
          category_slug: string
          created_at: string
          id: string
          sort_order: number | null
          subcategory: string | null
          title: string
          video_id: string
        }
        Insert: {
          category_slug: string
          created_at?: string
          id?: string
          sort_order?: number | null
          subcategory?: string | null
          title: string
          video_id: string
        }
        Update: {
          category_slug?: string
          created_at?: string
          id?: string
          sort_order?: number | null
          subcategory?: string | null
          title?: string
          video_id?: string
        }
        Relationships: []
      }
      repairs: {
        Row: {
          created_at: string
          id: string
          meta_description: string | null
          meta_title: string | null
          slug: string
          status: Database["public"]["Enums"]["repair_status"]
          title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          meta_description?: string | null
          meta_title?: string | null
          slug: string
          status?: Database["public"]["Enums"]["repair_status"]
          title: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          meta_description?: string | null
          meta_title?: string | null
          slug?: string
          status?: Database["public"]["Enums"]["repair_status"]
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      rss_sources: {
        Row: {
          country_default: string | null
          created_at: string
          enabled: boolean | null
          feed_url: string
          id: string
          name: string
        }
        Insert: {
          country_default?: string | null
          created_at?: string
          enabled?: boolean | null
          feed_url: string
          id?: string
          name: string
        }
        Update: {
          country_default?: string | null
          created_at?: string
          enabled?: boolean | null
          feed_url?: string
          id?: string
          name?: string
        }
        Relationships: []
      }
      shops_links: {
        Row: {
          country: string | null
          created_at: string
          id: string
          status: Database["public"]["Enums"]["shop_link_status"]
          title: string
          type: Database["public"]["Enums"]["shop_link_type"]
          url: string
          user_id: string
        }
        Insert: {
          country?: string | null
          created_at?: string
          id?: string
          status?: Database["public"]["Enums"]["shop_link_status"]
          title: string
          type?: Database["public"]["Enums"]["shop_link_type"]
          url: string
          user_id: string
        }
        Update: {
          country?: string | null
          created_at?: string
          id?: string
          status?: Database["public"]["Enums"]["shop_link_status"]
          title?: string
          type?: Database["public"]["Enums"]["shop_link_type"]
          url?: string
          user_id?: string
        }
        Relationships: []
      }
      user_roles: {
        Row: {
          created_at: string
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_admin: { Args: never; Returns: boolean }
    }
    Enums: {
      app_role: "admin" | "user"
      listing_category: "pojazd" | "czesc"
      listing_status: "pending" | "approved" | "rejected" | "archived"
      repair_media_kind: "image" | "youtube"
      repair_module_type:
        | "objawy"
        | "czesci"
        | "narzedzia"
        | "instrukcja"
        | "foto_video"
      repair_status: "draft" | "pending" | "published"
      shop_link_status: "pending" | "approved" | "rejected"
      shop_link_type: "sklep" | "usluga" | "katalog"
      source_type: "rss" | "user"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["admin", "user"],
      listing_category: ["pojazd", "czesc"],
      listing_status: ["pending", "approved", "rejected", "archived"],
      repair_media_kind: ["image", "youtube"],
      repair_module_type: [
        "objawy",
        "czesci",
        "narzedzia",
        "instrukcja",
        "foto_video",
      ],
      repair_status: ["draft", "pending", "published"],
      shop_link_status: ["pending", "approved", "rejected"],
      shop_link_type: ["sklep", "usluga", "katalog"],
      source_type: ["rss", "user"],
    },
  },
} as const
