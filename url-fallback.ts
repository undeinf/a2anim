import axios, { AxiosResponse, AxiosRequestConfig, AxiosError } from "axios";
import * as microsoftTeams from "@microsoft/teams-js";
import { PubSubTopic } from "../components/CommonToast/topics";
import { PubSubMessenger } from "../third-party";

// Define your secondary/backup URL here
const SECONDARY_URL = "https://your-secondary-fallback-url.com/api";

export class AxiosJWTDecorator {

  /**
   * Tries primary URL first. If it fails, falls back to SECONDARY_URL.
   * If SECONDARY_URL also fails, invokes handleError and throws error.
   */
  private async executeWithFallback<R>(
    primaryUrl: string,
    requestFn: (targetUrl: string) => Promise<R>
  ): Promise<R> {
    const urlsToTry = [primaryUrl, SECONDARY_URL];

    for (let i = 0; i < urlsToTry.length; i++) {
      const currentUrl = urlsToTry[i];
      const isLast = i === urlsToTry.length - 1;

      try {
        // As soon as this succeeds, return result immediately and exit
        return await requestFn(currentUrl);
      } catch (error) {
        if (isLast) {
          // Both primary and secondary failed -> handle error and throw
          this.handleError(error);
          throw error;
        }
        console.warn(`Primary request to ${currentUrl} failed. Retrying with fallback: ${SECONDARY_URL}`);
      }
    }

    throw new Error("All URL attempts failed");
  }

  public async get<T = any, R = AxiosResponse<T>>(
    url: string,
    config?: AxiosRequestConfig,
    needAuthorizationHeader: boolean = true
  ): Promise<R> {
    if (needAuthorizationHeader) {
      config = await this.setupAuthorizationHeader(config);
    }
    return this.executeWithFallback(url, (targetUrl) =>
      axios.get<T, R>(targetUrl, config)
    );
  }

  public async delete<T = any, R = AxiosResponse<T>>(
    url: string,
    data?: any,
    config?: AxiosRequestConfig
  ): Promise<R> {
    config = await this.setupAuthorizationHeader(config);
    if (data) {
      config.headers = config.headers || {};
      config.headers["Content-Type"] = "application/json; charset=utf-8";
      config.data = data;
    }
    return this.executeWithFallback(url, (targetUrl) =>
      axios.delete<T, R>(targetUrl, config)
    );
  }

  public async post<T = any, R = AxiosResponse<T>>(
    url: string,
    data?: any,
    config?: AxiosRequestConfig,
    needAuthorizationHeader: boolean = true
  ): Promise<R> {
    if (needAuthorizationHeader) {
      config = await this.setupAuthorizationHeader(config);
    }
    return this.executeWithFallback(url, (targetUrl) =>
      axios.post<T, R>(targetUrl, data, config)
    );
  }

  public async put<T = any, R = AxiosResponse<T>>(
    url: string,
    data?: any,
    config?: AxiosRequestConfig,
    needAuthorizationHeader: boolean = true
  ): Promise<R> {
    if (needAuthorizationHeader) {
      config = await this.setupAuthorizationHeader(config);
    }
    return this.executeWithFallback(url, (targetUrl) =>
      axios.put<T, R>(targetUrl, data, config)
    );
  }

  private handleError(error: any): void {
    const errorObj: AxiosError = error as AxiosError;
    PubSubMessenger.publish(PubSubTopic.SERVICE_ERROR, {
      code: errorObj?.response?.status || 400,
      message: errorObj?.response?.data || "Service Failed",
      data: errorObj,
    });
  }

  private async setupAuthorizationHeader(
    config?: AxiosRequestConfig
  ): Promise<AxiosRequestConfig> {
    microsoftTeams.initialize();

    return new Promise<AxiosRequestConfig>((resolve, reject) => {
      const authTokenRequest = {
        successCallback: (token: string) => {
          if (!config) {
            config = axios.defaults;
          }
          config.headers = config.headers || {};
          config.headers["Authorization"] = `Bearer ${token}`;
          resolve(config);
        },
        failureCallback: (error: string) => {
          console.error("Error from getAuthToken: ", error);
          window.location.href = "/signin";
        },
        resources: ["https://graph.microsoft.com"],
      };
      microsoftTeams.authentication.getAuthToken(authTokenRequest);
    });
  }
}

const axiosJWTDecoratorInstance = new AxiosJWTDecorator();
export default axiosJWTDecoratorInstance;
