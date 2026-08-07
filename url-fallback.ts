import axios, { AxiosResponse, AxiosRequestConfig, AxiosError } from "axios";
import * as microsoftTeams from "@microsoft/teams-js";
import { PubSubTopic } from "../components/CommonToast/topics";
import { PubSubMessenger } from "../third-party";

export class AxiosJWTDecorator {

  // Executes requests sequentially and short-circuits on the first success
  private async executeWithFallback<R>(
    urls: string | string[],
    requestFn: (targetUrl: string) => Promise<R>
  ): Promise<R> {
    // Normalize input so it's always an array of strings
    const urlList = Array.isArray(urls) ? urls : [urls];

    for (let i = 0; i < urlList.length; i++) {
      const currentUrl = urlList[i];
      const isLast = i === urlList.length - 1;

      try {
        // Passes a single string URL to requestFn, avoiding "url1,url2" concatenation
        return await requestFn(currentUrl);
      } catch (error) {
        if (isLast) {
          this.handleError(error);
          throw error;
        }
        console.warn(`Request to ${currentUrl} failed. Retrying with next fallback URL...`);
      }
    }

    throw new Error("All fallback URLs failed.");
  }

  public async get<T = any, R = AxiosResponse<T>>(
    url: string | string[],
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
    url: string | string[],
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
    url: string | string[],
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
    url: string | string[],
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
